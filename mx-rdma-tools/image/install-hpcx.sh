#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

echo "--------------- install hpxc -------------------"
# example : ENV_DOWNLOAD_HPCX_URL=https://content.mellanox.com/hpc/hpc-x/v2.19/hpcx-v2.19-gcc-mlnx_ofed-ubuntu22.04-cuda12-x86_64.tbz
HPCX_DEST_DIR="/opt/hpcx"
HPCX_DISTRIBUTION=$( echo "${ENV_DOWNLOAD_HPCX_URL}" | awk -F'/' '{print $NF}' | sed 's?.tbz??'  )
echo "download ${HPCX_DISTRIBUTION} from ${ENV_DOWNLOAD_HPCX_URL}"

cd /tmp
wget -q -O - ${ENV_DOWNLOAD_HPCX_URL} | tar xjf -
grep -IrlF "/build-result/${HPCX_DISTRIBUTION}" ${HPCX_DISTRIBUTION} | xargs -rd'\n' sed -i -e "s:/build-result/${HPCX_DISTRIBUTION}:${HPCX_DEST_DIR}:g"
sed -i -E 's?mydir=.*?mydir='"${HPCX_DEST_DIR}"'?' ${HPCX_DISTRIBUTION}/hpcx-init.sh
mv ${HPCX_DISTRIBUTION} ${HPCX_DEST_DIR}


echo "--------------- install Bandwidthtest -------------------"
echo "build cuda sample: ${ENV_VERSION_CUDA_SAMPLE}"

rm -rf /tmp/build || true
mkdir /tmp/build
cd /tmp/build
wget --no-check-certificate https://github.com/NVIDIA/cuda-samples/archive/refs/tags/${ENV_VERSION_CUDA_SAMPLE}.tar.gz
tar xzvf ${ENV_VERSION_CUDA_SAMPLE}.tar.gz
cd cuda-samples*/Samples/1_Utilities/bandwidthTest
make -j20
ls
rm -rf /buildCudaSample || true
mkdir /buildCudaSample
install bandwidthTest /buildCudaSample/
cd /tmp
rm -rf /tmp/build

echo "--------------- install nvbandwidth -------------------"
echo "build nvbandwidth: ${ENV_VERSION_NVBANDWIDTH}"
apt install  -y --no-install-recommends  wget cmake
