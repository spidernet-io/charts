#!/bin/bash

# for base image tag

set -x

CURRENT_FILENAME=`basename $0`
CURRENT_DIR_PATH=$(cd `dirname $0`; pwd)
cd ${CURRENT_DIR_PATH}

VAR_NCCL_BASE=${VAR_NCCL_BASE:-"true"}
echo "VAR_NCCL_BASE=${VAR_NCCL_BASE}"

# https://hub.docker.com/r/nvidia/cuda
# nvidia/cuda:12.5.1-cudnn-runtime-ubuntu22.04

if [ "$VAR_NCCL_BASE" == "true" ] ; then
    #
    export ENV_BASEIMAGE_CUDA_VERISON=${ENV_BASEIMAGE_CUDA_VERISON:-"12.5.1"}
    export ENV_BASEIMAGE_OS_VERISON=${ENV_BASEIMAGE_OS_VERISON:-"ubuntu22.04"}
    export ENV_BASEIMAGE_FULL_NAME=nvidia/cuda:${ENV_BASEIMAGE_CUDA_VERISON}-cudnn-runtime-${ENV_BASEIMAGE_OS_VERISON}
    export ENV_BUILD_TOOLS_IMAGE_NAME=nvidia/cuda:${ENV_BASEIMAGE_CUDA_VERISON}-cudnn-devel-${ENV_BASEIMAGE_OS_VERISON}
    #
    export ENV_INSTALL_HPCX=true
    # https://developer.nvidia.com/networking/hpc-x
    export ENV_VERSION_HPCX=${ENV_VERSION_HPCX:-"v2.19"}
    export ENV_DOWNLOAD_HPCX_URL="https://content.mellanox.com/hpc/hpc-x/${ENV_VERSION_HPCX}/hpcx-${ENV_VERSION_HPCX}-gcc-mlnx_ofed-${ENV_BASEIMAGE_OS_VERISON}-cuda12-x86_64.tbz"
    # https://github.com/NVIDIA/nccl-tests/tags
    export ENV_VERSION_NCCLTEST=${ENV_VERSION_NCCLTEST:-"v2.13.10"}
    # NCCL 2.22.3, for CUDA 12.5, ubuntu 22.04
    # https://developer.nvidia.com/cuda-downloads
    export ENV_CUDA_DEB_SOURCE="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb"
    # https://github.com/NVIDIA/nvbandwidth
    # 2024.8.14
    export ENV_VERSION_NVBANDWIDTH=${ENV_VERSION_NVBANDWIDTH:-"v0.5"}
    # https://github.com/NVIDIA/gdrcopy/tree/master
    # 2024.7.30
    export ENV_GDRCOPY_COMMIT=${ENV_GDRCOPY_COMMIT:-"1366e20d140c5638fcaa6c72b373ac69f7ab2532"}
    # https://github.com/NVIDIA/cuda-samples
    export ENV_VERSION_CUDA_SAMPLE=${ENV_VERSION_CUDA_SAMPLE:-"v12.5"}
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
fi 

# for cuda and libgdrapi.so
export ENV_LD_LIBRARY_PATH="/usr/local/cuda-12.5/compat:/usr/lib/x86_64-linux-gnu"

# https://github.com/linux-rdma/perftest
export ENV_VERSION_PERFTEST=${ENV_VERSION_PERFTEST:-"24.04.0-0.41"}

# https://www.tcpdump.org/release
export ENV_VERSION_LIBCAP=${ENV_VERSION_LIBCAP:-"libpcap-1.10.5"}
export ENV_VERSION_TCPDUMP=${ENV_VERSION_TCPDUMP:-"tcpdump-4.99.5"}

export ENV_DOWNLOAD_OFED_DEB_SOURCE="https://linux.mellanox.com/public/repo/mlnx_ofed/latest/ubuntu22.04/mellanox_mlnx_ofed.list"

echo "------------------------ Generate Dockerfile ---------------------------"

GenerateDockerfile(){
    pwd
    rm -f  Dockerfile || true
    cp Dockerfile.template Dockerfile

    ALL_ENV=$(printenv | grep ENV)
    OLD=$IFS
    IFS=$'\n'
    for ITEM in ${ALL_ENV} ;do
        KEY=$( echo "$ITEM" | awk -F'=' '{print $1}' )
        VALUE=$( echo "$ITEM" | sed 's?'"${KEY}"='??' )
        echo "KEY=${KEY}         VALUE=${VALUE}"
        sed -i 's?<<'"${KEY}"'>>?'"${VALUE}"'?g'  Dockerfile
    done
    IFS=$OLD
}
GenerateDockerfile


echo ""
echo "------------------------ show Dockerfile ---------------------------"
cat Dockerfile
echo ""



