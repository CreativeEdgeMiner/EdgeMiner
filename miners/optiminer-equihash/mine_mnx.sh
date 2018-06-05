#!/bin/bash

# General options

# The following line did not have any effect on my system but might reduce CPU usage on some.
# export GPU_SYNC_OBJECTS=1
export GPU_FORCE_64BIT_PTR=1

# Example pools
echo "Adjust the pool data below and remove this line!"


# suprnova.cc
POOL=eu.minexpool.nl:9999
USER=XHAjkFKAvTwwwf8RCQshXjLuHxjkZ3KwvB.
PASSWORD=x

cd "$(dirname "$0")"
while true
do
  echo "Executing $./optiminer-equihash -s $POOL -u $USER -p $PASSWORD -a equihash96_5 --watchdog-timeout 30 --watchdog-cmd "./watchdog-cmd.sh" $@"
  ./optiminer-equihash -s $POOL -u $USER -p $PASSWORD -a equihash96_5 --watchdog-timeout 30 --watchdog-cmd "./watchdog-cmd.sh" $@
  if [ $? -eq 134 ]
  then
    break
  fi
done

