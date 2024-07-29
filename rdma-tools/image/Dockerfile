# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

ARG CUDA_DEV_IMAGE_NAME

#============= build tools============

FROM ${CUDA_DEV_IMAGE_NAME} as buildtools
# TARGETOS is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETOS
# TARGETARCH is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETARCH

ARG VERSION_PERFTEST
ENV VERSION_PERFTEST=${VERSION_PERFTEST}

# Mellanox OFED (latest)
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget \
    && wget -qO - https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox | apt-key add -  \
    && cd /etc/apt/sources.list.d/ && wget https://linux.mellanox.com/public/repo/mlnx_ofed/latest/ubuntu22.04/mellanox_mlnx_ofed.list

# build perftest
#fix warning: debconf: delaying package configuration, since apt-utils is not installed
ARG DEBIAN_FRONTEND=noninteractive
RUN  apt-get install -y --no-install-recommends libibverbs-dev librdmacm-dev libibumad-dev libpci-dev \
      && apt-get install -y --no-install-recommends automake libtool make
WORKDIR /
RUN echo "build perftest ${VERSION_PERFTEST}" && wget --no-check-certificate https://github.com/linux-rdma/perftest/archive/refs/tags/${VERSION_PERFTEST}.tar.gz \
      &&  tar xzvf ${VERSION_PERFTEST}.tar.gz \
      &&  cd perftest-${VERSION_PERFTEST}  \
      && ./autogen.sh \
      && CUDA_H_PATH=`find /usr/local -name "cuda.h"` \
      && ./configure CUDA_H_PATH=${CUDA_H_PATH} -prefix=/buildperftest \
      && make && make install \

# install hpcx and nccltest
ARG DOWNLOAD_HPCX_URL
ENV DOWNLOAD_HPCX_URL=${DOWNLOAD_HPCX_URL}
ARG VERSION_NCCLTEST
ENV VERSION_NCCLTEST=${VERSION_NCCLTEST}
COPY /install-hpcx.sh /install-hpcx.sh
RUN chmod +x /install-hpcx.sh \
    && /install-hpcx.sh

#========== root image ==============
ARG BASE_IMAGE
FROM ${BASE_IMAGE} as rootfs

# TARGETOS is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETOS
# TARGETARCH is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETARCH

ARG GIT_COMMIT_VERSION
ENV GIT_COMMIT_VERSION=${GIT_COMMIT_VERSION}
ARG GIT_COMMIT_TIME
ENV GIT_COMMIT_TIME=${GIT_COMMIT_TIME}
ARG VERSION
ENV VERSION=${VERSION}

ARG LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

COPY /install-tools.sh /install-tools.sh
COPY /test.sh /test.sh
COPY /tools /tools

# Change the number to force the generation of a new git-tree SHA. Useful when
# we want to re-run 'apt-get upgrade' for stale images.
ENV FORCE_BUILD=1

#fix warning: debconf: delaying package configuration, since apt-utils is not installed
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y

WORKDIR /
RUN chmod +x /tools/* && mv /tools/* /usr/sbin && rm -rf /tools
RUN chmod +x /install-tools.sh && /install-tools.sh && rm -f /install-tools.sh

COPY --from=buildtools /buildperftest/bin/*   /usr/bin/
COPY --from=buildtools /buildnccltest/*       /usr/bin/
COPY --from=buildtools /opt/hpcx              /opt/hpcx

# HPC-X Environment variables
COPY ./printpaths.sh /tmp
RUN source /opt/hpcx/hpcx-init.sh && \
    hpcx_load && \
    # Uncomment to stop a run early with the ENV definitions for the below section
    # /tmp/printpaths.sh ENV && false && \
    # Preserve environment variables in new login shells \
    alias install='install --owner=0 --group=0' && \
    /tmp/printpaths.sh export \
      | install --mode=644 /dev/stdin /etc/profile.d/hpcx-env.sh && \
    # Preserve environment variables (except *PATH*) when sudoing
    install -d --mode=0755 /etc/sudoers.d && \
    /tmp/printpaths.sh \
      | sed -E -e '{ \
          # Convert NAME=value to just NAME \
          s:^([^=]+)=.*$:\1:g ; \
          # Filter out any variables with PATH in their names \
          /PATH/d ; \
          # Format them into /etc/sudoers env_keep directives \
          s:^.*$:Defaults env_keep += "\0":g \
        }' \
      | install --mode=440 /dev/stdin /etc/sudoers.d/hpcx-env && \
    # Register shared libraries with ld regardless of LD_LIBRARY_PATH
    echo $LD_LIBRARY_PATH | tr ':' '\n' \
      | install --mode=644 /dev/stdin /etc/ld.so.conf.d/hpcx.conf && \
    rm /tmp/printpaths.sh
RUN ldconfig


# check binary
RUN chmod +x /test.sh && /test.sh && rm -f /test.sh

CMD ["/usr/bin/sleep","infinity"]
