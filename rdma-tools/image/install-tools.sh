#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

InstallNccl(){

  cd /tmp
  rm * -rf || true
  apt-get install -y ca-certificates
  wget --no-check-certificate ${ENV_CUDA_DEB_SOURCE}
  dpkg -i *.deb
  apt-get update
  apt install -y libnccl2 libnccl-dev
  rm * -rf || true

  echo "* soft memlock unlimited" >> /etc/security/limits.conf
  echo "* hard memlock unlimited" >> /etc/security/limits.conf
}

InstallSSH(){
  mkdir /root/.ssh
  ssh-keygen -t ed25519 -f ~/.ssh/id_spidernet -N ""
  cat ~/.ssh/id_spidernet.pub >> ~/.ssh/authorized_keys

  sed -i 's/[ #]\(.*StrictHostKeyChecking \).*/ \1no/g' /etc/ssh/ssh_config
  echo "    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config
  sed -i 's/#\(StrictModes \).*/\1no/g' /etc/ssh/sshd_config

  service ssh start
}

InstallOfed(){
  # required by perftest
  # Mellanox OFED (latest)
  wget -qO - https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox | apt-key add -
  cd /etc/apt/sources.list.d/
  wget ${ENV_DOWNLOAD_OFED_DEB_SOURCE}
  apt-get install -y --no-install-recommends  libibverbs-dev libibumad3 libibumad-dev librdmacm-dev
}


packages=(
  iproute2
  # ibv_rc_pingpong
  ibverbs-utils
  # ibstat
  infiniband-diags
  # rping
  rdmacm-utils
  smc-tools
  lshw
  #lspci
  pciutils
  vim
  # ibdiagnet ibnetdiscover
  ibutils
  iperf3
  # ping
  iputils-ping
  # ssh server
  openssh-server
  curl
  jq
)

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends wget

# tzdata is one of the dependencies and a timezone must be set
# to avoid interactive prompt when it is being installed
ln -fs /usr/share/zoneinfo/UTC /etc/localtime

InstallOfed
apt-get install -y --no-install-recommends "${packages[@]}"
InstallNccl
InstallSSH

apt-get purge --auto-remove
apt-get clean
rm -rf /var/lib/apt/lists/*
