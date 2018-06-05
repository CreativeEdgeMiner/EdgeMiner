#!/bin/bash

SCRIPT_PATH="$(dirname $0)"
cd $SCRIPT_PATH


export GPU_MAX_HEAP_SIZE=100
export GPU_USE_SYNC_OBJECTS=1
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100

./ethdcrminer64 -epool us1.ethermine.org:4444 -ewal 34989a5480af30e3ddedb4926f18814dd0ddff96.Nate epsw x -mode 1 -allpools 1 
