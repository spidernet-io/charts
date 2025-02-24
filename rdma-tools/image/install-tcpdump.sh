#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

echo "build libpcap ${ENV_VERSION_LIBCAP}"
echo "build tcpdump ${ENV_VERSION_TCPDUMP}"

cd /tmp
rm -rf * || true

apt-get update
apt-get install -y --no-install-recommends bison make gcc flex xz-utils

wget https://www.tcpdump.org/release/${ENV_VERSION_LIBCAP}.tar.xz 
wget https://www.tcpdump.org/release/${ENV_VERSION_TCPDUMP}.tar.xz 

tar -xvf ${ENV_VERSION_LIBCAP}.tar.xz 
cd /tmp/${ENV_VERSION_LIBCAP}
./configure 
make && make install

tar -xvf ${ENV_VERSION_TCPDUMP}.tar.xz 
cd /tmp/${ENV_VERSION_TCPDUMP}
./configure 
make && make install
