#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

packages=(
  iproute2
  # ibv_rc_pingpong
  ibverbs-utils
  # ib_send_lat
  perftest
  # ibstat
  infiniband-diags
  smc-tools
  lshw
  #lspci
  pciutils
  vim
  wget
  # ibdiagnet ibnetdiscover
  ibutils
  iperf3
  # ping
  iputils-ping
)


export DEBIAN_FRONTEND=noninteractive
apt-get update

# tzdata is one of the dependencies and a timezone must be set
# to avoid interactive prompt when it is being installed
ln -fs /usr/share/zoneinfo/UTC /etc/localtime

apt-get install -y --no-install-recommends "${packages[@]}"

# cuda
#wget --no-check-certificate https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
#dpkg -i cuda-keyring_1.1-1_all.deb
#apt-get update

# apt-get -y install cuda-toolkit-12-5
# nvidia-smi
# apt-get install -y cuda-drivers-555
#apt-get install -y nvidia-utils-555


apt-get purge --auto-remove
apt-get clean
rm -rf /var/lib/apt/lists/*
