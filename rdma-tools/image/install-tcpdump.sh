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


#!/bin/bash

# Check if environment variables are defined
if [ -z "${ENV_VERSION_LIBCAP}" ] || [ -z "${ENV_VERSION_TCPDUMP}" ]; then
    echo "Environment variables ENV_VERSION_LIBCAP or ENV_VERSION_TCPDUMP are not defined"
    exit 1
fi

# Download files
wget --no-check-certificate https://www.tcpdump.org/release/${ENV_VERSION_LIBCAP}.tar.xz || { echo "Failed to download libcap"; exit 1; }
wget --no-check-certificate https://www.tcpdump.org/release/${ENV_VERSION_TCPDUMP}.tar.xz || { echo "Failed to download tcpdump"; exit 1; }


echo "========= File List ========="
ls -lh

# Check if files exist
if [ ! -f "${ENV_VERSION_LIBCAP}.tar.xz" ] || [ ! -f "${ENV_VERSION_TCPDUMP}.tar.xz" ]; then
    echo "Downloaded files do not exist"
    exit 1
fi

# Extract files
tar -xvf ${ENV_VERSION_LIBCAP}.tar.xz || { echo "Failed to extract libcap"; exit 1; }
tar -xvf ${ENV_VERSION_TCPDUMP}.tar.xz || { echo "Failed to extract tcpdump"; exit 1; }

cd /tmp/${ENV_VERSION_LIBCAP}
./configure 
make && make install

cd /tmp/${ENV_VERSION_TCPDUMP}
./configure 
make && make install
echo "installed directory: $(which tcpdump )"

cd /tmp
rm -rf * || true
