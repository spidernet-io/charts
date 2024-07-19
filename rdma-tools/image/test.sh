#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

ip a &>/dev/null
which show_gids &>/dev/null
which ibdev2netdev &>/dev/null
which ibv_rc_pingpong &>/dev/null
which ib_send_lat &>/dev/null
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


#which nvidia-smi &>/dev/null


exit 0
