#!/bin/bash

# for base image tag

export BASEIMAGE_CUDA_VERISON=${BASEIMAGE_CUDA_VERISON:-"12.5.1"}

export BASEIMAGE_OS_VERISON=${BASEIMAGE_OS_VERISON:-"ubuntu22.04"}

# https://hub.docker.com/r/nvidia/cuda
# nvidia/cuda:12.5.1-cudnn-runtime-ubuntu22.04
export BASEIMAGE_FULL_NAME=nvidia/cuda:${BASEIMAGE_CUDA_VERISON}-cudnn-runtime-${BASEIMAGE_OS_VERISON}

