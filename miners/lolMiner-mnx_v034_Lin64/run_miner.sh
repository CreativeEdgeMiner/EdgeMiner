#!/bin/bash

#################################
## Begin of user-editable part ##
#################################

CFGFILE=./example_config.cfg		#Insert your configuration file name here


#################################
##  End of user-editable part  ##
#################################

cd "$(dirname "$0")"
while true
do
  ./lolMiner-mnx --use-config $CFGFILE $@
  if [ $? -eq 134 ]
  then
    break
  fi
done
