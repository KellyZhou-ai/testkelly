#! /bin/bash

datevalue=$(date +"%y%m%d_%H%M%S")
path=$datevalue'_AMAlog'

list_ama_process()
{
        echo "current running process for AMA:"
        ps -ef | grep azuremonitoragent | grep -v grep

}

AzureVM_log_collector()
{
        mkdir $path
        mkdir $path/waagent
        cp /var/log/waagent.log* $path/waagent/ 1>/dev/null
        echo "waagent log collected"
        sleep 1s
        mkdir $path/Microsoft.Azure.Monitor.AzureMonitorLinuxAgent
        cp -r /var/log/azure/Microsoft.Azure.Monitor.AzureMonitorLinuxAgent/* $path/Microsoft.Azure.Monitor.AzureMonitorLinuxAgent/ 1>/dev/null
        echo "AMA extention log collected"
        sleep 1s
        mkdir $path/mdsd
        cp /var/opt/microsoft/azuremonitoragent/log/* $path/mdsd/ 1>/dev/null
        echo "mdsd log collected"
        sleep 1s
        mkdir $path/DCR
        cp -r /etc/opt/microsoft/azuremonitoragent/* $path/DCR/ 1>/dev/null
        echo "DCR config collected"
        sleep 1s
        mkdir $path/Config
        cp -r /var/lib/waagent/Microsoft.Azure.Monitor.AzureMonitorLinuxAgent-*/status/* $path/Config/ 1>/dev/null
        cp -r /var/lib/waagent/Microsoft.Azure.Monitor.AzureMonitorLinuxAgent-*/config/* $path/Config/ 1>/dev/null
        echo "config&status collected"
        sleep 1s

echo "collection complete at $path"
}


Arc_log_collector()
{
        mkdir $path
        mkdir $path/GC_Extention
        cp /var/lib/GuestConfig/ext_mgr_logs/* $path/GC_Extention/ 1>/dev/null
        echo "gc extention log collected"
        sleep 1s
        mkdir $path/Microsoft.Azure.Monitor.AzureMonitorLinuxAgent
        cp -r /var/lib/GuestConfig/extension_logs/Microsoft.Azure.Monitor.AzureMonitorLinuxAgent* $path/Microsoft.Azure.Monitor.AzureMonitorLinuxAgent/ 1>/dev/null
        echo "AMA extention log collected"
        sleep 1s
        mkdir $path/mdsd
        cp /var/opt/microsoft/azuremonitoragent/log/* $path/mdsd/ 1>/dev/null
        echo "mdsd log collected"
        sleep 1s
        mkdir $path/DCR
        cp -r /etc/opt/microsoft/azuremonitoragent/* $path/DCR/ 1>/dev/null
        echo "DCR config collected"
        sleep 1s
        mkdir $path/Config
        cp -r /var/lib/waagent/Microsoft.Azure.Monitor.AzureMonitorLinuxAgent-*/status/* $path/Config/ 1>/dev/null
        cp -r /var/lib/waagent/Microsoft.Azure.Monitor.AzureMonitorLinuxAgent-*/config/* $path/Config/ 1>/dev/null
        echo "config&status collected"
        sleep 1s

echo "collection complete at $path"
}


pack_logs()
{
    if [ $(command -v zip |wc -l) == "1" ]; then
    zip -q -r $path.zip $path/ 1>/dev/null
    echo "packed at $path.zip"
    else
    tar -zcvf $path.tar.gz $path/ 1>/dev/null
    echo "packed at $path.tar.gz"
    fi
}

countdown()
(
  IFS=:
  set -- $*
  secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ))
  while [ $secs -gt 0 ]
  do
    sleep 1 &
    printf "\r%02d:%02d:%02d" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
    secs=$(( $secs - 1 ))
    wait
  done
  echo
)

echo "***********************************************"
echo "Welcome to use AMA log collector tool"
echo "***********************************************"

main()
{
echo "start log collecting"
sleep 1s

if [ $(find /var/lib/waagent/ -type d -name Microsoft.Azure.Monitor.AzureMonitorLinuxAgent-1.10* | wc -l) != "0" ]; then
         echo "Detected old AMA version, please upgrade the extention version first"
elif [ $(ps -ef | grep himds | grep -v grep|wc -l) != "0" ]; then
         echo "Arc service detected, collecting logs for Azure Arc"
         ps -ef | grep himds | grep -v grep
         sleep 5s
         Arc_log_collector
else
          echo "No Arc service detected, collecting logs for azure VM"
          sleep 5s
          AzureVM_log_collector
fi
pack_logs
}
#troubleshooting

list_ama_process
if [ $(ps -ef | grep mdsd | grep -v grep|wc -l) == "0" ]; then
        read -p "No mdsd process detected, would you like to restart azuremonitoragent(Y/N):" ifyes
        if [ "$ifyes" == "Y" ]; then
                systemctl start azuremonitoragent && systemctl enable azuremonitoragent 1>/dev/null
                echo "waiting for 10 seconds"
                countdown 00:00:10
                main
        elif [ "$ifyes" == "N" ]; then
                main
        else
                echo "please enter Y/N"
        fi
elif [ $(ps -ef | grep telegraf | grep -v grep|wc -l) == "0" ]; then
        echo "No telegraf process detected, check if there is DCR for preformance counter collection"
        sleep 5s
        if [ $(cat /etc/opt/microsoft/azuremonitoragent/config-cache/configchunks/*.json | grep -i counters | wc -l) != "0" ]; then
                read -p "Got perf DCR, but no running telegraf. Would you like to re-eable telegraf(Y/N):" ifyes
                        if [ "$ifyes" == "Y" ]; then
                                systemctl start metrics-sourcer.service && systemctl enable metrics-sourcer.service 1>/dev/null
                                systemctl start metrics-extension.service && systemctl enable metrics-extension.service 1>/dev/nul
                                echo "waiting for 10 seconds"
                                countdown 00:00:10
                                main
                        elif [ "$ifyes" == "N" ]; then
                                main
                        else
                                echo "please enter Y/N"
                        fi
        else
                echo "No Perf DCR found. No telegraf running is expected"
                sleep 5s
                main
        fi

else
        echo "Expected processes are running"
        main



fi
