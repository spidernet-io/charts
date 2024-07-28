#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

InstallNccl(){
  CUDA_MAJOR=` echo ${CUDA_VERSION} | grep -o -E "[0-9]+\.[0-9]+" `

  if [ "${CUDA_MAJOR}" == "12.5" ] ; then
        # NCCL 2.22.3, for CUDA 12.5, ubuntu 22.04
        apt-get install -y ca-certificates
        wget --no-check-certificate https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
        dpkg -i cuda-keyring_1.0-1_all.deb
        apt-get update
        apt install -y libnccl2 libnccl-dev
        rm -f cuda-keyring_1.0-1_all.deb
  else
       echo "error, support CUDA version: ${CUDA_VERSION} , ${CUDA_MAJOR}"
       exit 1
  fi

  echo "* soft memlock unlimited" >> /etc/security/limits.conf
  echo "* hard memlock unlimited" >> /etc/security/limits.conf
}

InstallSSH(){
  mkdir /root/.ssh
  ssh-keygen -t ed25519 -f ~/.ssh/id_spidernet -N ""
  cat ~/.ssh/id_spidernet.pub >> ~/.ssh/authorized_keys
  service ssh start
}


packages=(
  iproute2
  # ibv_rc_pingpong
  ibverbs-utils
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
  # ssh server
  openssh-server
)

export DEBIAN_FRONTEND=noninteractive
apt-get update

# tzdata is one of the dependencies and a timezone must be set
# to avoid interactive prompt when it is being installed
ln -fs /usr/share/zoneinfo/UTC /etc/localtime

apt-get install -y --no-install-recommends "${packages[@]}"
InstallNccl
InstallSSH

apt-get purge --auto-remove
apt-get clean
rm -rf /var/lib/apt/lists/*
