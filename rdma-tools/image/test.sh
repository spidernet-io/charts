#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o nounset

echo "ENV_INSTALL_HPCX=${ENV_INSTALL_HPCX}"

if [ "${ENV_INSTALL_HPCX}" == "true" ] ; then 
    source /opt/hpcx/hpcx-init.sh
    hpcx_load

    which nvbandwidth &>/dev/null
    which bandwidthTest &>/dev/null

    all_reduce_perf -h
    mpirun --allow-run-as-root -h

    echo "MPI_HOME=${MPI_HOME}"
fi 

ip a &>/dev/null
which show_gids &>/dev/null
which ibdev2netdev &>/dev/null
which ibv_rc_pingpong &>/dev/null
which ibstat &>/dev/null
which smc_run &>/dev/null
which lspci &>/dev/null
which lshw &>/dev/null
which rdma &>/dev/null
which ibdiagnet &>/dev/null
which ibnetdiscover &>/dev/null
which ibhosts &>/dev/null
which ibping &>/dev/null
which iperf3 &>/dev/null
which ping &>/dev/null
which tcpdump &>/dev/null

#ib_send_bw -h
ib_send_bw |& grep "Did not detect devices"

echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"


exit 0
