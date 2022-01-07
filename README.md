# AMALinuxLogCollector

## Introduction
This script is designed to collect related logs from AMA Linux Agent on Azure VM or Azure Arc servers. 
https://docs.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-overview

## Prerequistes
Bash environment

## Usage
`wget https://raw.githubusercontent.com/KellyZhou-ai/testkelly/main/AMAlogcollector.sh && bash AMAlogcollector.sh`

## Function
1. Check your running process for AMA.
2. Check if the AMA is using old version AMA for Linux 1.10*. If so,need to upgrade extention first. 
3. Let you choose if you want to start/enable MDSD process if there is no running MDSD process.
4. Let you choose if you want to enable telegraf if there is no running telegraf process when performance counter DCR detected.
5. Check if it is an Arc server.
6. For azure VM, collect:

   -Waagent log
   
   -AMA extention log
   
   -MDSD log
   
   -DCR config
   
   -Configuration & Status
6. For azure arc VM, collect:

   -GC extention log
   
   -AMA extention log
   
   -MDSD log
   
   -DCR config
   
   -Configuration & Status
