#!/bin/bash

# for base image tag

export BASEIMAGE_CUDA_VERISON=${BASEIMAGE_CUDA_VERISON:-"12.5.1"}
export BASEIMAGE_OS_VERISON=${BASEIMAGE_OS_VERISON:-"ubuntu22.04"}
export LD_LIBRARY_PATH="/usr/local/cuda-12.5/compat"

# https://github.com/linux-rdma/perftest
export VERSION_PERFTEST=${VERSION_PERFTEST:-"24.04.0-0.41"}

#====================================

# https://hub.docker.com/r/nvidia/cuda
# nvidia/cuda:12.5.1-cudnn-runtime-ubuntu22.04
export BASEIMAGE_FULL_NAME=nvidia/cuda:${BASEIMAGE_CUDA_VERISON}-cudnn-runtime-${BASEIMAGE_OS_VERISON}
export CUDA_DEV_IMAGE_NAME=nvidia/cuda:${BASEIMAGE_CUDA_VERISON}-cudnn-devel-${BASEIMAGE_OS_VERISON}
