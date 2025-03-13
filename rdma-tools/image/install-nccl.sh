#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

if [ "${ENV_INSTALL_HPCX}" == "false" ] ; then
    exit 0
fi

InstallNccl() {
  echo " install nccl"

  cd /tmp
  rm * -rf || true
  apt-get install -y ca-certificates
  wget --no-check-certificate ${ENV_CUDA_DEB_SOURCE}
  dpkg -i *.deb
  apt-get update
  apt install --allow-change-held-packages -y libnccl2 libnccl-dev
  rm * -rf || true

  echo "ulimit -l 2000000" >>/etc/bash.bashrc
  echo "* soft memlock unlimited" >>/etc/security/limits.conf
  echo "* hard memlock unlimited" >>/etc/security/limits.conf
}

InstallEnv() {
  echo " install enviroment for hpc-x"
  chmod +x /printpaths.sh
  # HPC-X Environment variables
  source /opt/hpcx/hpcx-init.sh
  hpcx_load

  # test
  /printpaths.sh ENV

  # Preserve environment variables in new login shells
  alias install='install --owner=0 --group=0'
  /printpaths.sh export |
    install --mode=644 /dev/stdin /etc/profile.d/hpcx-env.sh

  # Preserve environment variables (except *PATH*) when sudoing
  install -d --mode=0755 /etc/sudoers.d
  /printpaths.sh |
    sed -E -e '{ s:^([^=]+)=.*$:\1:g ;  /PATH/d ;  s:^.*$:Defaults env_keep += "\0":g  }' |
    install --mode=440 /dev/stdin /etc/sudoers.d/hpcx-env

  # Register shared libraries with ld regardless of LD_LIBRARY_PATH
  echo $LD_LIBRARY_PATH | tr ':' '\n' |
    install --mode=644 /dev/stdin /etc/ld.so.conf.d/hpcx.conf

  rm /printpaths.sh
  ldconfig
}

InstallGdrCopy() {
  echo "install gdrcopy library"
  cd /buildGdrcopy
  dpkg -i *.deb
  rm -rf /buildGdrcopy
}


export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends wget

InstallNccl
InstallEnv

apt-get purge --auto-remove
apt-get clean
rm -rf /var/lib/apt/lists/*
