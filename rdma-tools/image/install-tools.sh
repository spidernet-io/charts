#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

InstallNccl(){
  echo " install nccl"

  cd /tmp
  rm * -rf || true
  apt-get install -y ca-certificates
  wget --no-check-certificate ${ENV_CUDA_DEB_SOURCE}
  dpkg -i *.deb
  apt-get update
  apt install --allow-change-held-packages -y libnccl2 libnccl-dev
  rm * -rf || true

  echo "ulimit -l 2000000" >> /etc/bash.bashrc
  echo "* soft memlock unlimited" >> /etc/security/limits.conf
  echo "* hard memlock unlimited" >> /etc/security/limits.conf
}

InstallSSH(){
  # for mpirun
  mkdir /root/.ssh
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
  cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

  sed -i 's/[ #]\(.*StrictHostKeyChecking \).*/ \1no/g' /etc/ssh/ssh_config
  echo "    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config
  sed -i 's/#\(StrictModes \).*/\1no/g' /etc/ssh/sshd_config
}

InstallOfedRepo(){
  # required by perftest
  echo " install ofed lib"
  # Mellanox OFED (latest)
  wget -qO - https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox | apt-key add -
  cd /etc/apt/sources.list.d/
  wget ${ENV_DOWNLOAD_OFED_DEB_SOURCE}
  apt-get update
}

InstallEnv(){
  echo " install enviroment for hpc-x"
    chmod +x /printpaths.sh
    # HPC-X Environment variables
    source /opt/hpcx/hpcx-init.sh
    hpcx_load

    # test
    /printpaths.sh ENV

    # Preserve environment variables in new login shells
    alias install='install --owner=0 --group=0'
    /printpaths.sh export \
      | install --mode=644 /dev/stdin /etc/profile.d/hpcx-env.sh

    # Preserve environment variables (except *PATH*) when sudoing
    install -d --mode=0755 /etc/sudoers.d
    /printpaths.sh \
      | sed -E -e '{ s:^([^=]+)=.*$:\1:g ;  /PATH/d ;  s:^.*$:Defaults env_keep += "\0":g  }' \
      | install --mode=440 /dev/stdin /etc/sudoers.d/hpcx-env

    # Register shared libraries with ld regardless of LD_LIBRARY_PATH
    echo $LD_LIBRARY_PATH | tr ':' '\n' \
      | install --mode=644 /dev/stdin /etc/ld.so.conf.d/hpcx.conf

    rm /printpaths.sh
    ldconfig
}


InstallGdrCopy(){
    echo "install gdrcopy library"
    cd /buildGdrcopy
    dpkg -i *.deb
    rm -rf  /buildGdrcopy
}


packages=(
  iproute2
  smc-tools
  lshw
  #lspci
  pciutils
  vim
  iperf3
  # ping
  iputils-ping
  iputils-arping
  # ssh server
  openssh-server
  curl
  jq
  inxi
  hwloc
  libgomp1
  kmod
  tcpdump
  ethtool
  iptables
  #--------------
  libibverbs-dev
  libibumad3
  libibumad-dev
  librdmacm-dev
  #infiniband-diags
  # ibstat
  infiniband-diags=2404mlnx51-1.2404066
  #ibverbs-utils
  # ibdiagnet ibnetdiscover
  ibutils2
  ibdump
  #ibutils
  ibverbs-utils=2404mlnx51-1.2404066
  #rdmacm-utils
  rdmacm-utils=2404mlnx51-1.2404066
)

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends wget

# tzdata is one of the dependencies and a timezone must be set
# to avoid interactive prompt when it is being installed
ln -fs /usr/share/zoneinfo/UTC /etc/localtime

InstallOfedRepo
apt-get install -y --no-install-recommends "${packages[@]}"
InstallNccl
InstallSSH
InstallEnv
InstallGdrCopy

apt-get purge --auto-remove
apt-get clean
rm -rf /var/lib/apt/lists/*
