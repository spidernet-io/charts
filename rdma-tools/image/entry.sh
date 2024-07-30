#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

source /usr/sbin/rdmatools

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
echo "----------- ip a ------------------"
ip a

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
echo "----------- nvidia-smi topo ------------------"
nvidia-smi topo -m || true

echo ""
echo "----------- nvidia-smi nvlink  ------------------"
nvidia-smi nvlink -s || true

echo ""
echo "----------- inxi  ------------------"
inxi -v8

echo ""
echo "----------- wait looply.... ---------- "
/usr/bin/sleep infinity
