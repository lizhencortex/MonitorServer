#!/bin/bash

if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

HAS_NVIDIA_DRIVER=$(which nvidia-smi)
if [ -z $HAS_NVIDIA_DRIVER ]; then
	echo NVIDIA driver not found, stop
	exit 1
else
    echo NVIDIA driver detected
fi

HAS_SUPERVISORD=$(which supervisord)
if [ -z $HAS_SUPERVISORD ]; then
	echo Supervisor not found, stop
	exit 1
else
    echo Supervisor detected
fi

CUDA90=$(ls /usr/local | grep cuda-9.0)
CUDA92=$(ls /usr/local | grep cuda-9.2)
CUDA10=$(ls /usr/local | grep cuda-10.0)
HAS_CUDA=$CUDA90$CUDA92$CUDA10
DPLOY_PATH="/opt/cortex"

if [ -z $HAS_CUDA ]; then
	echo CUDA library not found, stop
	exit 1
fi

if [ -n $CUDA10 ]; then
    echo CUDA10.0 detected
    wget http://monitor.cortexlabs.ai/nodelist/cortex-cuda10.0
    wget http://monitor.cortexlabs.ai/nodelist/miner-cuda10.0
    mv cortex-cuda10.0 cortex
    mv miner-cuda10.0 cuda_miner
else
    if [ -n $CUDA92 ]; then
        echo CUDA9.2 detected
        wget http://monitor.cortexlabs.ai/nodelist/cortex-cuda9.2
        wget http://monitor.cortexlabs.ai/nodelist/miner-cuda9.2
        mv cortex-cuda9.2 cortex
        mv miner-cuda9.2 cuda_miner
    else
        echo CUDA9.0 detected
        wget http://monitor.cortexlabs.ai/nodelist/cortex-cuda9.0
        wget http://monitor.cortexlabs.ai/nodelist/miner-cuda9.0
        mv cortex-cuda9.0 cortex
        mv miner-cuda9.0 cuda_miner
    fi
fi

if [ -n "$1" ]; then
    DPLOY_PATH="$1" 
fi

mkdir -p $DPLOY_PATH
wget http://monitor.cortexlabs.ai/nodelist/cortex-package.tar.gz
tar zxvf cortex-package.tar.gz
mv -r ./cortex-package/script/* $DPLOY_PATH/
mv cortex $DPLOY_PATH/
mv cuda_miner $DPLOY_PATH/
chmod +x ./cortex-package/service/cortex-monitor.sh
mv ./cortex-package/service/cortex-monitor.sh /etc/init.d/
update-rc.d cortex-monitor.sh defaults
mv ./cortex-package/supervisor-config/*.conf /etc/supervisor/conf.d/

supervisorctl reload
sleep 5
service cortex-monitor.sh start

echo deploy finish

