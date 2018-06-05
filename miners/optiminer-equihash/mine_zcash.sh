#!/bin/bash

# General options

# The following line did not have any effect on my system but might reduce CPU usage on some.
# export GPU_SYNC_OBJECTS=1
export GPU_FORCE_64BIT_PTR=1
ADDITIONAL=

# Example pools
echo "Adjust the pool data below and remove this line!"


# Flypool (encrypted connection):
# uses cash address as user
POOL=zstratum+tls://eu1-zcash.flypool.org:3443
USER=t1Yszagk1jBjdyPfs2GxXx1GWcfn6fdTuFJ.worker
PASSWORD=x

# Suprnova (encrypted connection):
#POOL=zstratum+tls://zec.suprnova.cc:2242
#USER=moobar.worker
#PASSWORD=x

# Nicehash:
# uses bitcoin address as user
#POOL=zstratum+tls://equihash.eu.nicehash.com:33357
#USER=3MkiMqn9UgzcvB2zJehnLiQG8woDx4CUit
#PASSWORD=x
#ADDITIONAL="--certificate nicehash.cert"

# Nanopool (encrypted connection):
#POOL=zstratum+tls://zec-eu1.nanopool.org:6633
#USER=19STEagfLfbb1XdTF9NCf5kmxZHGchSiZj.worker
#PASSWORD=x
#ADDITIONAL="--certificate nanopool.cert"

# Miningpoolhub
#POOL=zstratum+tls://us-east.equihash-hub.miningpoolhub.com:20570
#USER=moobar.worker
#PASSWORD=x
#ADDITIONAL="--certificate miningpoolhub.cert"


cd "$(dirname "$0")"
while true
do
  ./optiminer-equihash -s $POOL -u $USER -p $PASSWORD --watchdog-timeout 30 -a equihash200_9 --watchdog-cmd "./watchdog-cmd.sh" $ADDITIONAL $@
  if [ $? -eq 134 ]
  then
    break
  fi
done

