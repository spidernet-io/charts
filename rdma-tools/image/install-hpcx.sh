#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

ENV_GITHUB_ARTIFACTORY=${ENV_GITHUB_ARTIFACTORY:-"github.com"}

if [ "${ENV_INSTALL_HPCX}" == "false" ] ; then
    exit 0
fi

ARCH=$(dpkg --print-architecture)

echo "--------------- install hpxc -------------------"
# example : ENV_DOWNLOAD_HPCX_URL=https://content.mellanox.com/hpc/hpc-x/v2.19/hpcx-v2.19-gcc-mlnx_ofed-ubuntu22.04-cuda12-x86_64.tbz
HPCX_DEST_DIR="/opt/hpcx"

case "${ARCH}" in
    amd64)
        HPCX_ARCH=x86_64
        ;;
    arm64)
        HPCX_ARCH=aarch64
        ;;
    *)
        echo "unsupported architecture for HPCX install: ${ARCH}" >&2
        exit 1
        ;;
esac

# Rewrite URL arch suffix to match actual build architecture.
# This allows a single committed Dockerfile to work for both x86_64 and arm64 buildx builds.
HPCX_URL=$(echo "${ENV_DOWNLOAD_HPCX_URL}" | sed "s/-x86_64\.tbz/-${HPCX_ARCH}.tbz/;s/-aarch64\.tbz/-${HPCX_ARCH}.tbz/")
HPCX_DISTRIBUTION=$(echo "${HPCX_URL}" | awk -F'/' '{print $NF}' | sed 's?.tbz??')
echo "download ${HPCX_DISTRIBUTION} from ${HPCX_URL}"

cd /tmp
wget -q -O - ${HPCX_URL} | tar xjf -
grep -IrlF "/build-result/${HPCX_DISTRIBUTION}" ${HPCX_DISTRIBUTION} | xargs -rd'\n' sed -i -e "s:/build-result/${HPCX_DISTRIBUTION}:${HPCX_DEST_DIR}:g"
sed -i -E 's?mydir=.*?mydir='"${HPCX_DEST_DIR}"'?' ${HPCX_DISTRIBUTION}/hpcx-init.sh
mv ${HPCX_DISTRIBUTION} ${HPCX_DEST_DIR}

echo "--------------- install nccltest -------------------"
echo "build nccl test version ${ENV_VERSION_NCCLTEST}"
mkdir /buildnccltest && cd /buildnccltest
wget --no-check-certificate  https://${ENV_GITHUB_ARTIFACTORY}/NVIDIA/nccl-tests/archive/refs/tags/${ENV_VERSION_NCCLTEST}.tar.gz
tar xvf ${ENV_VERSION_NCCLTEST}.tar.gz
cd nccl-tests*
source ${HPCX_DEST_DIR}/hpcx-init.sh
hpcx_load
make BUILDDIR=/buildnccltest MPI=1 CUDA_HOME=/usr/local/cuda

echo "--------------- install Bandwidthtest -------------------"
echo "build cuda sample: ${ENV_VERSION_CUDA_SAMPLE}"

rm -rf /tmp/build || true
mkdir /tmp/build
cd /tmp/build
wget --no-check-certificate https://${ENV_GITHUB_ARTIFACTORY}/NVIDIA/cuda-samples/archive/refs/tags/${ENV_VERSION_CUDA_SAMPLE}.tar.gz
tar xzvf ${ENV_VERSION_CUDA_SAMPLE}.tar.gz
cd cuda-samples*/Samples/1_Utilities/bandwidthTest
apt-get update
apt-get install -y --no-install-recommends cmake

if [ -f Makefile ] || [ -f makefile ] ; then
    make -j20
    BW_BIN="./bandwidthTest"
else
    rm -rf build || true
    mkdir -p build
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
    cmake --build build -j20
    BW_BIN=$(find build -maxdepth 3 -type f -name bandwidthTest -perm -111 | head -n 1)
fi

[ -n "${BW_BIN}" ] || { echo "error: failed to find bandwidthTest binary" ; exit 1 ; }
[ -x "${BW_BIN}" ] || { echo "error: bandwidthTest binary is not executable: ${BW_BIN}" ; exit 1 ; }

ls
rm -rf /buildCudaSample || true
mkdir /buildCudaSample
install "${BW_BIN}" /buildCudaSample/bandwidthTest
cd /tmp
rm -rf /tmp/build


echo "--------------- install gdrcopy lib -------------------"
echo "build gdrcopy with commit ${ENV_GDRCOPY_COMMIT} "
apt install  -y --no-install-recommends  build-essential devscripts debhelper fakeroot pkg-config dkms unzip

rm -rf /tmp/build || true
mkdir /tmp/build
cd /tmp/build
wget --no-check-certificate https://${ENV_GITHUB_ARTIFACTORY}/NVIDIA/gdrcopy/archive/${ENV_GDRCOPY_COMMIT}.zip
unzip *.zip
ls
cd gdrcopy*/packages
CUDA=/usr/local/cuda  ./build-deb-packages.sh -k
rm -rf /buildGdrcopy || true
mkdir /buildGdrcopy
cp  libgdrapi_*.deb  /buildGdrcopy
cp  gdrcopy-tests_*.deb  /buildGdrcopy


echo "--------------- install nvbandwidth -------------------"
echo "build nvbandwidth: ${ENV_VERSION_NVBANDWIDTH}"
apt install  -y --no-install-recommends  wget cmake

rm -rf /tmp/build || true
mkdir /tmp/build
cd /tmp/build
wget --no-check-certificate https://${ENV_GITHUB_ARTIFACTORY}/NVIDIA/nvbandwidth/archive/refs/tags/${ENV_VERSION_NVBANDWIDTH}.tar.gz
tar xzvf *.tar.gz
cd nvbandwidth-*/
./debian_install.sh
cmake .
make
rm -rf /buildNvbandwidth || true
mkdir /buildNvbandwidth
cp nvbandwidth /buildNvbandwidth/
cd /tmp
rm -rf /tmp/build



