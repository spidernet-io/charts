#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

echo "build perftest ${ENV_VERSION_PERFTEST}"

# required by perftest
# Mellanox OFED (latest)
apt-get update \
    && apt-get install -y --no-install-recommends wget \
    && wget -qO - https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox | apt-key add -  \
    && cd /etc/apt/sources.list.d/ && wget ${ENV_DOWNLOAD_OFED_DEB_SOURCE}

apt-get update
apt-get install -y --no-install-recommends libibverbs-dev librdmacm-dev libibumad-dev libpci-dev \
      && apt-get install -y --no-install-recommends automake libtool make

cd /tmp
rm -rf * || true

wget --no-check-certificate https://github.com/linux-rdma/perftest/archive/refs/tags/${ENV_VERSION_PERFTEST}.tar.gz
tar xzvf ${ENV_VERSION_PERFTEST}.tar.gz
cd perftest-${ENV_VERSION_PERFTEST}
./autogen.sh
CUDA_H_PATH=`find /usr/local -name "cuda.h"`
./configure CUDA_H_PATH=${CUDA_H_PATH} -prefix=/buildperftest
make && make install
