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

InstallEnv(){
    chmod +x /printpaths.sh
    # HPC-X Environment variables
    source /opt/hpcx/hpcx-init.sh
    hpcx_load
    # Uncomment to stop a run early with the ENV definitions for the below section
    # /printpaths.sh ENV && false
    # Preserve environment variables in new login shells
    alias install='install --owner=0 --group=0'
    /printpaths.sh export \
      | install --mode=644 /dev/stdin /etc/profile.d/hpcx-env.sh
    # Preserve environment variables (except *PATH*) when sudoing
    install -d --mode=0755 /etc/sudoers.d
    /printpaths.sh \
      | sed -E -e '{ \
          # Convert NAME=value to just NAME \
          s:^([^=]+)=.*$:\1:g ; \
          # Filter out any variables with PATH in their names \
          /PATH/d ; \
          # Format them into /etc/sudoers env_keep directives \
          s:^.*$:Defaults env_keep += "\0":g \
        }' \
      | install --mode=440 /dev/stdin /etc/sudoers.d/hpcx-env
    # Register shared libraries with ld regardless of LD_LIBRARY_PATH
    echo $LD_LIBRARY_PATH | tr ':' '\n' \
      | install --mode=644 /dev/stdin /etc/ld.so.conf.d/hpcx.conf
    rm /printpaths.sh
    ldconfig
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
InstallEnv

apt-get purge --auto-remove
apt-get clean
rm -rf /var/lib/apt/lists/*
