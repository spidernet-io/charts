#!/bin/bash

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

if [ -z "${ENV_BASEIMAGE_CUDA_VERISON:-}" ] ; then
  exit 0
fi

CUDA_SHORT=$(echo "${ENV_BASEIMAGE_CUDA_VERISON}" | cut -d. -f1,2)
CU_VER=$(echo "${CUDA_SHORT}" | tr -d .)

export PIP_DISABLE_PIP_VERSION_CHECK=1
export PIP_NO_CACHE_DIR=1

PIP_RETRIES=${PIP_RETRIES:-10}
PIP_TIMEOUT=${PIP_TIMEOUT:-600}

python3 -m pip install --upgrade pip --retries "${PIP_RETRIES}" --timeout "${PIP_TIMEOUT}"
TORCH_WHL_INDEX_URL=${TORCH_WHL_INDEX_URL:-"https://download.pytorch.org/whl/cu${CU_VER}"}
pip3 install torch numpy packaging --extra-index-url "${TORCH_WHL_INDEX_URL}" --retries "${PIP_RETRIES}" --timeout "${PIP_TIMEOUT}" --no-cache-dir

NVSHMEM_VERSION_RAW=${ENV_NVSHMEM_VERSION:-"3.4.5"}
NVSHMEM_VERSION=${NVSHMEM_VERSION_RAW#v}
NVSHMEM_VERSION=${NVSHMEM_VERSION%-*}

apt-get update
apt-get install -y --no-install-recommends xz-utils

rm -rf /opt/nvshmem || true
mkdir -p /opt/nvshmem

NVSHMEM_TARBALL_URL="https://developer.download.nvidia.cn/compute/redist/nvshmem/${NVSHMEM_VERSION}/builds/cuda12/txz/agnostic/x64/libnvshmem-linux-x86_64-${NVSHMEM_VERSION}_cuda12-archive.tar.xz"
curl -fsSL -o /tmp/nvshmem.tar.xz "${NVSHMEM_TARBALL_URL}"

rm -rf /tmp/nvshmem-extract || true
mkdir -p /tmp/nvshmem-extract
tar -xf /tmp/nvshmem.tar.xz -C /tmp/nvshmem-extract
rm -f /tmp/nvshmem.tar.xz

NVSHMEM_EXTRACT_ROOT=$(find /tmp/nvshmem-extract -mindepth 1 -maxdepth 1 -type d | head -n 1)
if [ -z "${NVSHMEM_EXTRACT_ROOT}" ] ; then
  echo "Failed to extract NVSHMEM tarball"
  exit 1
fi

cp -a "${NVSHMEM_EXTRACT_ROOT}/"* /opt/nvshmem/
rm -rf /tmp/nvshmem-extract

rm -rf /tmp/deepep || true
mkdir -p /tmp/deepep
cd /tmp/deepep
curl -fsSL -o DeepEP.zip https://${ENV_GITHUB_ARTIFACTORY}/deepseek-ai/DeepEP/archive/${ENV_DEEPEP_VERSION}.zip
unzip DeepEP.zip
rm -rf /opt/DeepEP || true
mv DeepEP-${ENV_DEEPEP_VERSION} /opt/DeepEP
DEEPEP_NVSHMEM_PATCH=/opt/DeepEP/third-party/nvshmem.patch

if ls /buildGdrcopy/libgdrapi_*.deb >/dev/null 2>&1 ; then
  dpkg -i /buildGdrcopy/libgdrapi_*.deb
fi

rm -rf /tmp/deepep
cd /opt/DeepEP
sed -i 's/#define NUM_CPU_TIMEOUT_SECS 100/#define NUM_CPU_TIMEOUT_SECS 1000/' csrc/kernels/configs.cuh
export TORCH_CUDA_ARCH_LIST="${ENV_TORCH_CUDA_ARCH_LIST}"
export NVSHMEM_DIR=/opt/nvshmem
export CFLAGS="${CFLAGS:-} -fcommon"
export CXXFLAGS="${CXXFLAGS:-} -fcommon"
MAX_JOBS=${ENV_BUILD_AND_DOWNLOAD_PARALLEL} pip wheel --no-build-isolation . -w /buildDeepEP
cd /
rm -rf /tmp/deepep

rm -rf /opt/DeepGEMM || true
git clone -b "${ENV_DEEPGEMM_VERSION}" --depth 1 https://${ENV_GITHUB_ARTIFACTORY}/deepseek-ai/DeepGEMM.git /opt/DeepGEMM
cd /opt/DeepGEMM
git submodule update --init --recursive
python setup.py bdist_wheel
cp dist/*.whl /buildDeepGEMM/
cd /
