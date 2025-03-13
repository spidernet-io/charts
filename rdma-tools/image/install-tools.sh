#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

InstallSSH() {
  # for mpirun
  mkdir /root/.ssh
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
  cat ~/.ssh/id_ed25519.pub >>~/.ssh/authorized_keys

  sed -i 's/[ #]\(.*StrictHostKeyChecking \).*/ \1no/g' /etc/ssh/ssh_config
  echo "    UserKnownHostsFile /dev/null" >>/etc/ssh/ssh_config
  sed -i 's/#\(StrictModes \).*/\1no/g' /etc/ssh/sshd_config
}

InstallOfedRepo() {
  # required by perftest
  echo " install ofed lib"
  # Mellanox OFED (latest)
  wget -qO - https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox | apt-key add -
  cd /etc/apt/sources.list.d/
  wget ${ENV_DOWNLOAD_OFED_DEB_SOURCE}
  apt-get update

  for ITEM in "infiniband-diags" "rdmacm-utils" "ibverbs-utils"; do
    VERSION=$(apt-cache show ${ITEM} | grep Version | grep mlnx | awk '{print $2}')
    [ -n "${VERSION}" ] || {
      echo "error, failed to find mlnx version "
      exit 1
    }
    apt-get install -y --no-install-recommends ${ITEM}=${VERSION}
  done

}


InstallGdrCopy() {
  echo "install gdrcopy library"
  cd /buildGdrcopy
  dpkg -i *.deb
  rm -rf /buildGdrcopy
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
  arping
  dnsutils
  # ssh server
  openssh-server
  curl
  jq
  inxi
  hwloc
  libgomp1
  kmod
  ethtool
  iptables
  #--------------
  libibverbs-dev
  libibumad3
  libibumad-dev
  librdmacm-dev
  # ibdiagnet ibnetdiscover
  ibutils2
  ibdump
  libelf1
  libltdl7
  libnuma1
  psmisc
)

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends wget gnupg2

# tzdata is one of the dependencies and a timezone must be set
# to avoid interactive prompt when it is being installed
ln -fs /usr/share/zoneinfo/UTC /etc/localtime

InstallOfedRepo
apt-get install -y --no-install-recommends "${packages[@]}"
InstallSSH
InstallGdrCopy

apt-get purge --auto-remove
apt-get clean
rm -rf /var/lib/apt/lists/*
