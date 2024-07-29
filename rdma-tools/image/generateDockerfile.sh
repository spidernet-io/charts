#!/bin/bash

CURRENT_FILENAME=$( basename $0 )
CURRENT_DIR_PATH=$(cd $(dirname $0); pwd)

# for base image tag

export ENV_BASEIMAGE_CUDA_VERISON=${ENV_BASEIMAGE_CUDA_VERISON:-"12.5.1"}
export ENV_BASEIMAGE_OS_VERISON=${ENV_BASEIMAGE_OS_VERISON:-"ubuntu22.04"}
export ENV_LD_LIBRARY_PATH="/usr/local/cuda-12.5/compat"

# https://github.com/linux-rdma/perftest
export ENV_VERSION_PERFTEST=${ENV_VERSION_PERFTEST:-"24.04.0-0.41"}
# https://github.com/NVIDIA/nccl-tests/tags
export ENV_VERSION_NCCLTEST=${ENV_VERSION_NCCLTEST:-"v2.13.10"}

# https://developer.nvidia.com/networking/hpc-x
export ENV_VERSION_HPCX=${ENV_VERSION_HPCX:-"v2.19"}
export ENV_DOWNLOAD_HPCX_URL="https://content.mellanox.com/hpc/hpc-x/${ENV_VERSION_HPCX}/hpcx-${ENV_VERSION_HPCX}-gcc-mlnx_ofed-${ENV_BASEIMAGE_OS_VERISON}-cuda12-x86_64.tbz"
export ENV_DOWNLOAD_OFED_DEB_SOURCE="https://linux.mellanox.com/public/repo/mlnx_ofed/latest/${ENV_BASEIMAGE_OS_VERISON}/mellanox_mlnx_ofed.list"

# https://hub.docker.com/r/nvidia/cuda
# nvidia/cuda:12.5.1-cudnn-runtime-ubuntu22.04
export ENV_BASEIMAGE_FULL_NAME=nvidia/cuda:${ENV_BASEIMAGE_CUDA_VERISON}-cudnn-runtime-${ENV_BASEIMAGE_OS_VERISON}
export ENV_CUDA_DEV_IMAGE_NAME=nvidia/cuda:${ENV_BASEIMAGE_CUDA_VERISON}-cudnn-devel-${ENV_BASEIMAGE_OS_VERISON}



echo "------------------------ Generate Dockerfile ---------------------------"

GenerateDockerfile(){
    cd ${CURRENT_DIR_PATH}
    rm -f  Dockerfile || true
    cp Dockerfile.template Dockerfile

    ALL_ENV=$(printenv | grep ENV)
    OLD=$IFS
    IFS=$'\n'
    for ITEM in ${ALL_ENV} ;do
        KEY=$( echo "$ITEM" | awk -F'=' '{print $1}' )
        VALUE=$( echo "$ITEM" | sed 's?'"${KEY}"='??' )
        echo "KEY=${KEY}         VALUE=${VALUE}"
        sed -i 's?<<'"${KEY}"'>>?'"${VALUE}"'?'  Dockerfile
    done
    IFS=$OLD
}
GenerateDockerfile
