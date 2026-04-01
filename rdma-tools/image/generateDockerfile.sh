#!/bin/bash

# for base image tag

set -x

CURRENT_FILENAME=`basename $0`
CURRENT_DIR_PATH=$(cd `dirname $0`; pwd)
cd ${CURRENT_DIR_PATH}

VAR_NCCL_BASE=${VAR_NCCL_BASE:-"true"}
DOCKER_IMAGE_REGISTRY=${DOCKER_IMAGE_REGISTRY:-"docker.io"}
BASE_GOLANG_IMAGE=${BASE_GOLANG_IMAGE:-"golang:1.24.1"}
echo "VAR_NCCL_BASE=${VAR_NCCL_BASE}"
echo "DOCKER_IMAGE_REGISTRY=${DOCKER_IMAGE_REGISTRY}"
echo "BASE_GOLANG_IMAGE=${BASE_GOLANG_IMAGE}"

TARGET_ARCH_RESOLVED=${ENV_TARGET_ARCH:-${TARGET_ARCH:-${TARGETARCH:-$(dpkg --print-architecture 2>/dev/null || uname -m)}}}
case "${TARGET_ARCH_RESOLVED}" in
    amd64|x86_64)
        TARGET_ARCH_CANONICAL=amd64
        DEFAULT_HPCX_ARCH=x86_64
        DEFAULT_CUDA_REPO_ARCH=x86_64
        DEFAULT_SYSTEM_LIB_DIR=/usr/lib/x86_64-linux-gnu
        ;;
    arm64|aarch64)
        TARGET_ARCH_CANONICAL=arm64
        DEFAULT_HPCX_ARCH=aarch64
        DEFAULT_CUDA_REPO_ARCH=sbsa
        DEFAULT_SYSTEM_LIB_DIR=/usr/lib/aarch64-linux-gnu
        ;;
    *)
        echo "unsupported target architecture: ${TARGET_ARCH_RESOLVED}" >&2
        exit 1
        ;;
esac
export ENV_TARGET_ARCH=${TARGET_ARCH_CANONICAL}

# https://hub.docker.com/r/nvidia/cuda
# nvidia/cuda:12.5.1-cudnn-runtime-ubuntu22.04

if [ "$VAR_NCCL_BASE" == "true" ] ; then
    #
    export ENV_BASEIMAGE_CUDA_VERISON=${ENV_BASEIMAGE_CUDA_VERISON:-"12.8.1"}
    export ENV_BASEIMAGE_OS_VERISON=${ENV_BASEIMAGE_OS_VERISON:-"ubuntu22.04"}
    export ENV_BASEIMAGE_FULL_NAME=${DOCKER_IMAGE_REGISTRY}/nvidia/cuda:${ENV_BASEIMAGE_CUDA_VERISON}-cudnn-runtime-${ENV_BASEIMAGE_OS_VERISON}
    export ENV_BUILD_TOOLS_IMAGE_NAME=${DOCKER_IMAGE_REGISTRY}/nvidia/cuda:${ENV_BASEIMAGE_CUDA_VERISON}-cudnn-devel-${ENV_BASEIMAGE_OS_VERISON}
    HPCX_ARCH=${ENV_HPCX_ARCH:-${HPCX_ARCH:-${DEFAULT_HPCX_ARCH}}}
    CUDA_REPO_ARCH=${ENV_CUDA_REPO_ARCH:-${CUDA_REPO_ARCH:-${DEFAULT_CUDA_REPO_ARCH}}}
    SYSTEM_LIB_DIR=${ENV_SYSTEM_LIB_DIR:-${SYSTEM_LIB_DIR:-${DEFAULT_SYSTEM_LIB_DIR}}}
    export ENV_HPCX_ARCH=${HPCX_ARCH}
    export ENV_CUDA_REPO_ARCH=${CUDA_REPO_ARCH}
    export ENV_SYSTEM_LIB_DIR=${SYSTEM_LIB_DIR}
    #
    export ENV_INSTALL_HPCX=true
    # https://developer.nvidia.com/networking/hpc-x
    export ENV_VERSION_HPCX=${ENV_VERSION_HPCX:-"v2.19"}
    export ENV_DOWNLOAD_HPCX_URL="https://content.mellanox.com/hpc/hpc-x/${ENV_VERSION_HPCX}/hpcx-${ENV_VERSION_HPCX}-gcc-mlnx_ofed-${ENV_BASEIMAGE_OS_VERISON}-cuda12-${HPCX_ARCH}.tbz"
    # https://github.com/NVIDIA/nccl-tests/tags
    export ENV_VERSION_NCCLTEST=${ENV_VERSION_NCCLTEST:-"v2.13.10"}
    # NCCL 2.22.3, for CUDA 12.5, ubuntu 22.04
    # https://developer.nvidia.com/cuda-downloads
    export ENV_CUDA_DEB_SOURCE="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/${CUDA_REPO_ARCH}/cuda-keyring_1.0-1_all.deb"
    # https://github.com/NVIDIA/nvbandwidth
    # 2024.8.14
    export ENV_VERSION_NVBANDWIDTH=${ENV_VERSION_NVBANDWIDTH:-"v0.5"}
    # https://github.com/NVIDIA/gdrcopy/tree/master
    # 2024.7.30
    export ENV_GDRCOPY_COMMIT=${ENV_GDRCOPY_COMMIT:-"1366e20d140c5638fcaa6c72b373ac69f7ab2532"}
    # https://github.com/NVIDIA/cuda-samples
    # 2024.7.30
    export ENV_VERSION_CUDA_SAMPLE=${ENV_VERSION_CUDA_SAMPLE:-"v12.8"}

    # https://github.com/NVIDIA/nvshmem/tags
    export ENV_NVSHMEM_VERSION=${ENV_NVSHMEM_VERSION:-"v3.4.5-0"}
    # CMake CUDA architectures list (e.g., 90 for Hopper, 100 for Blackwell)
    export ENV_CMAKE_CUDA_ARCHITECTURES=${ENV_CMAKE_CUDA_ARCHITECTURES:-"90;100"}
else
    export ENV_BASEIMAGE_CUDA_VERISON=
    export ENV_BASEIMAGE_OS_VERISON=
    export ENV_BASEIMAGE_FULL_NAME=ubuntu:22.04
    export ENV_BUILD_TOOLS_IMAGE_NAME=ubuntu:22.04
    # do not install
    export ENV_INSTALL_HPCX=false
    export ENV_VERSION_HPCX=
    export ENV_DOWNLOAD_HPCX_URL=
    export ENV_VERSION_NCCLTEST=
    export ENV_CUDA_DEB_SOURCE=
    export ENV_VERSION_NVBANDWIDTH=
    export ENV_GDRCOPY_COMMIT=
    export ENV_VERSION_CUDA_SAMPLE=
    export ENV_NVSHMEM_VERSION=
    export ENV_CMAKE_CUDA_ARCHITECTURES=
fi 

export ENV_BUILD_GOLANG_SERVER_IMAGE_NAME=${DOCKER_IMAGE_REGISTRY}/${BASE_GOLANG_IMAGE}
export ENV_DEEPEP_VERSION=${ENV_DEEPEP_VERSION:-"v1.2.1"}
export ENV_DEEPGEMM_VERSION=${ENV_DEEPGEMM_VERSION:-"nv_dev_4ff3f54"}
export ENV_UCX_VERSION=${ENV_UCX_VERSION:-"v1.19.1"}
export ENV_INSTALL_CUDA_TOOLKIT=${ENV_INSTALL_CUDA_TOOLKIT:-"true"}

export ENV_BUILD_AND_DOWNLOAD_PARALLEL=${ENV_BUILD_AND_DOWNLOAD_PARALLEL:-"8"}
# Allow external GITHUB_ARTIFACTORY to override the default github.com mirror
export ENV_GITHUB_ARTIFACTORY=${GITHUB_ARTIFACTORY:-${ENV_GITHUB_ARTIFACTORY:-"github.com"}}
export ENV_TORCH_CUDA_ARCH_LIST=${ENV_TORCH_CUDA_ARCH_LIST:-"9.0;10.0"}

# for cuda and libgdrapi.so
if [ -n "${ENV_BASEIMAGE_CUDA_VERISON}" ] ; then
    CUDA_SHORT=$(echo "${ENV_BASEIMAGE_CUDA_VERISON}" | cut -d. -f1,2)
    SYSTEM_LIB_DIR=${ENV_SYSTEM_LIB_DIR:-""}
    SYSTEM_LIB_DIR=${SYSTEM_LIB_DIR:-${DEFAULT_SYSTEM_LIB_DIR}}
    export ENV_LD_LIBRARY_PATH="/usr/local/cuda-${CUDA_SHORT}/compat:${SYSTEM_LIB_DIR}"
else
    SYSTEM_LIB_DIR=${ENV_SYSTEM_LIB_DIR:-""}
    SYSTEM_LIB_DIR=${SYSTEM_LIB_DIR:-${DEFAULT_SYSTEM_LIB_DIR}}
    export ENV_LD_LIBRARY_PATH="${SYSTEM_LIB_DIR}"
fi

# https://github.com/linux-rdma/perftest
export ENV_VERSION_PERFTEST=${ENV_VERSION_PERFTEST:-"24.04.0-0.41"}

# https://www.tcpdump.org/release
export ENV_VERSION_LIBCAP=${ENV_VERSION_LIBCAP:-"libpcap-1.10.5"}
export ENV_VERSION_TCPDUMP=${ENV_VERSION_TCPDUMP:-"tcpdump-4.99.5"}

export ENV_DOWNLOAD_OFED_DEB_SOURCE="https://linux.mellanox.com/public/repo/mlnx_ofed/latest/ubuntu22.04/mellanox_mlnx_ofed.list"

echo "------------------------ Generate Dockerfile ---------------------------"

GenerateDockerfile(){
    pwd
    rm -f Dockerfile || true
    cp Dockerfile.template Dockerfile

    # 只获取以 ENV_ 开头的变量，避免将系统所有的环境变量都进行循环处理
    ALL_ENV=$(printenv | grep "^ENV_")
    
    # 确定 sed -i 的语法（兼容 macOS 和 Linux）
    SED_INPLACE_ARG=("-i")
    if ! sed --version >/dev/null 2>&1 ; then
        SED_INPLACE_ARG=("-i" "")
    fi

    OLD=$IFS
    IFS=$'\n'
    for ITEM in ${ALL_ENV} ;do
        # 使用 Shell 自带的参数扩展，不再依赖 awk 和 sed
        KEY="${ITEM%%=*}"
        VALUE="${ITEM#*=}"
        
        echo "Replacing <<${KEY}>> with ${VALUE}"
        
        # 这里的分隔符建议用一个极罕见的字符，或者对 VALUE 进行转义
        # 修复 112 行：使用 @ 作为分隔符通常比 ? 更安全
        sed "${SED_INPLACE_ARG[@]}" "s@<<${KEY}>>@${VALUE}@g" Dockerfile
    done
    IFS=$OLD

    if [ "${VAR_NCCL_BASE}" = "true" ] ; then
        sed "${SED_INPLACE_ARG[@]}" '/##NO_DEEPEP_BEGIN/,/##NO_DEEPEP_END/d' Dockerfile
        sed "${SED_INPLACE_ARG[@]}" '/##DEEPEP_BEGIN/d' Dockerfile
        sed "${SED_INPLACE_ARG[@]}" '/##DEEPEP_END/d' Dockerfile
    else
        sed "${SED_INPLACE_ARG[@]}" '/##DEEPEP_BEGIN/,/##DEEPEP_END/d' Dockerfile
        sed "${SED_INPLACE_ARG[@]}" '/##NO_DEEPEP_BEGIN/d' Dockerfile
        sed "${SED_INPLACE_ARG[@]}" '/##NO_DEEPEP_END/d' Dockerfile
        sed "${SED_INPLACE_ARG[@]}" '/ENV_DEEPEP_VERSION=/d' Dockerfile
        sed "${SED_INPLACE_ARG[@]}" '/ENV_DEEPGEMM_VERSION=/d' Dockerfile
    fi
}
GenerateDockerfile

echo ""
echo "------------------------ show Dockerfile ---------------------------"
cat Dockerfile
echo ""
