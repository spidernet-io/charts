#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

source /usr/sbin/rdmatools

echo ""
echo "namespace/pod: ${ENV_POD_NAMESPACE}/${ENV_POD_NAME}"
echo "node name: ${ENV_LOCAL_NODE_NAME}"
echo "node ip: ${ENV_LOCAL_NODE_IP}"
echo ""

echo "GIT_COMMIT_VERSION: ${GIT_COMMIT_VERSION}"
echo "GIT_COMMIT_TIME: ${GIT_COMMIT_TIME}"
echo "VERSION: ${VERSION}"

echo ""
echo "----------- start ssh---------"
service ssh start

echo ""
echo "=---------- ulimit ----------------"
ulimit -l 2000000
ulimit -a

echo ""
echo "----------- env: LD_LIBRARY_PATH ------------------"
echo ${LD_LIBRARY_PATH}

echo ""
echo "----------- env: PATH ------------------"
echo ${PATH}

echo ""
echo "----------- env: HPCX_DIR ------------------"
echo ${PATH}

echo ""
echo "----------- show_gids ------------------"
show_gids

echo ""
echo "----------- ip ------------------"
ip a
echo ""
ip route
echo ""
ip rule

echo ""
echo "=---------- rdma device information ----------------"
GetLocalRoceDeviceIP

echo ""
echo "----------- ibstat ------------------"
ibstat

echo ""
echo "----------- lshw ------------------"
lshw -c network -businfo

echo ""
echo "----------- ibdev2netdev ------------------"
ibdev2netdev

echo ""
echo "----------- nvidia-smi ------------------"
nvidia-smi || true

echo ""
echo "----------- nvidia-smi topo ------------------"
nvidia-smi topo -m || true

echo ""
echo "----------- lstopo ------------------"
lstopo

echo ""
echo "----------- nvidia-smi nvlink  ------------------"
nvidia-smi nvlink -s || true

echo ""
echo "----------- inxi  ------------------"
inxi -v8

echo ""
echo "----------- gdrcopy_sanity  ------------------"
major=`fgrep gdrdrv /proc/devices | cut -b 1-4` || true
if [ -n "${major}" ] ; then
    mknod /dev/gdrdrv c $major 0
    chmod a+w+r /dev/gdrdrv
    gdrcopy_sanity || true
else
    echo "error, failed to detect gdrdrv"
fi

echo ""
echo "----------- lsmod  ------------------"
lsmod

echo ""
echo "----------- wait looply.... ---------- "
touch /tmp/ready
/usr/bin/sleep infinity
