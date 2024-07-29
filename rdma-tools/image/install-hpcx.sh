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
sed -E 's?mydir=.*?mydir='"${HPCX_DEST_DIR}"'?' ${HPCX_DISTRIBUTION}/hpcx-init.sh
mv ${HPCX_DISTRIBUTION} ${HPCX_DEST_DIR}


echo "--------------- install nccltest -------------------"
echo "build nccl test version ${ENV_VERSION_NCCLTEST}"
mkdir /buildnccltest && cd /buildnccltest
wget --no-check-certificate  https://github.com/NVIDIA/nccl-tests/archive/refs/tags/${ENV_VERSION_NCCLTEST}.tar.gz
tar xvf ${ENV_VERSION_NCCLTEST}.tar.gz
cd nccl-tests*
source ${HPCX_DEST_DIR}/hpcx-init.sh
hpcx_load
make BUILDDIR=/buildnccltest MPI=1 CUDA_HOME=/usr/local/cuda
