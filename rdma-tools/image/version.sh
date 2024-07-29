#!/bin/bash

# for base image tag

export BASEIMAGE_CUDA_VERISON=${BASEIMAGE_CUDA_VERISON:-"12.5.1"}
export BASEIMAGE_OS_VERISON=${BASEIMAGE_OS_VERISON:-"ubuntu22.04"}
export LD_LIBRARY_PATH="/usr/local/cuda-12.5/compat"

# https://github.com/linux-rdma/perftest
export VERSION_PERFTEST=${VERSION_PERFTEST:-"24.04.0-0.41"}
# https://github.com/NVIDIA/nccl-tests/tags
export VERSION_NCCLTEST=${VERSION_NCCLTEST:-"v2.13.10"}


# https://developer.nvidia.com/networking/hpc-x
VERSION_HPCX=${VERSION_HPCX:-"v2.19"}
export DOWNLOAD_HPCX_URL="https://content.mellanox.com/hpc/hpc-x/${VERSION_HPCX}/hpcx-${VERSION_HPCX}-gcc-mlnx_ofed-ubuntu22.04-cuda12-x86_64.tbz"


#====================================

# https://hub.docker.com/r/nvidia/cuda
# nvidia/cuda:12.5.1-cudnn-runtime-ubuntu22.04
export BASEIMAGE_FULL_NAME=nvidia/cuda:${BASEIMAGE_CUDA_VERISON}-cudnn-runtime-${BASEIMAGE_OS_VERISON}
export CUDA_DEV_IMAGE_NAME=nvidia/cuda:${BASEIMAGE_CUDA_VERISON}-cudnn-devel-${BASEIMAGE_OS_VERISON}


