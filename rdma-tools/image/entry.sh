#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

source /usr/sbin/rdmatools

service ssh start
ulimit -l 2000000
ulimit -a

# gdrcopy
if [ ! -f "/dev/gdrdrv" ] ; then
    major=`fgrep gdrdrv /proc/devices | cut -b 1-4` || true
    if [ -n "${major}" ] ; then
        mknod /dev/gdrdrv c $major 0
        chmod a+w+r /dev/gdrdrv
    else
        echo "error, failed to detect gdrdrv"
    fi
fi


ENV_LIST="
GIT_COMMIT_VERSION
GIT_COMMIT_TIME
VERSION
ENV_POD_NAMESPACE
ENV_POD_NAME
ENV_LOCAL_NODE_NAME
ENV_LOCAL_NODE_IP
ENV_BASEIMAGE_CUDA_VERISON
ENV_BASEIMAGE_OS_VERISON
ENV_VERSION_PERFTEST
ENV_VERSION_LIBCAP
ENV_VERSION_TCPDUMP
ENV_VERSION_NCCLTEST
ENV_VERSION_HPCX
LD_LIBRARY_PATH
PATH
HPCX_DIR
"

echo "=================================== environment ============================================="
OLD=$IFS
IFS=$'\n'
for ENVVAR in ${ENV_LIST} ; do
    IFS="${OLD}"
    [ -n "${ENVVAR}" ] || continue
    printf "%s=%s\n" "${ENVVAR}" "$( eval echo \$${ENVVAR} )"
    echo ""
done

#===================================================

COMMAND_LIST="
lshw -c network -businfo
lstopo
inxi -v8

ip a
ip route
ip rule
show_gids
ibdev2netdev
ibstat
ibstatus
ibaddr
GetLocalRdmaDeviceIP
PrintAllInfinibandNetHosts
PrintAllInfinibandAddress
PrintAllInfinibandSubnet

nvidia-smi
nvidia-smi topo -m
nvidia-smi nvlink -s

gdrcopy_sanity
lsmod
"

OLD=$IFS
IFS=$'\n'
for COMMAND in ${COMMAND_LIST} ; do
    IFS="${OLD}"
    [ -n "${COMMAND}" ] || continue
    echo "======================== command: ${COMMAND} ============================="
    eval ${COMMAND}  || true
    echo ""
done

echo "======================== wait looply.... ============================="
touch /tmp/ready
/usr/bin/sleep infinity

