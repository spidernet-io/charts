# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

ARG BASE_IMAGE
ARG CUDA_DEV_IMAGE_NAME

#============= build tools============

FROM ${CUDA_DEV_IMAGE_NAME} as buildtools
# TARGETOS is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETOS
# TARGETARCH is an automatic platform ARG enabled by Docker BuildKit.
ARG TARGETARCH

ARG VERSION_PERFTEST
ENV VERSION_PERFTEST=${VERSION_PERFTEST}

#fix warning: debconf: delaying package configuration, since apt-utils is not installed
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y wget libibverbs-dev librdmacm-dev libibumad-dev libpci-dev automake libtool make

WORKDIR /
RUN  wget --no-check-certificate https://github.com/linux-rdma/perftest/archive/refs/tags/${VERSION_PERFTEST}.tar.gz \
      &&  tar xzvf ${VERSION_PERFTEST}.tar.gz \
      &&  cd perftest-${VERSION_PERFTEST}  \
      && ./autogen.sh \
      && CUDA_H_PATH=`find /usr/local -name "cuda.h"` \
      && ./configure CUDA_H_PATH=${CUDA_H_PATH} -prefix=/build \
      && make && make install


#========== root image ==============
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
RUN chmod +x /install-tools.sh && /install-tools.sh && rm -f /install-tools.sh
RUN chmod +x /tools/* && mv /tools/* /usr/sbin && rm -rf /tools

COPY --from=buildtools /build/bin/*   /usr/bin/

# check binary
RUN chmod +x /test.sh && /test.sh && rm -f /test.sh


CMD ["/usr/bin/sleep","infinity"]
