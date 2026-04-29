#!/bin/bash

# Copyright 2024 Authors of spidernet-io
# SPDX-License-Identifier: Apache-2.0

set -x
set -o xtrace
set -o errexit
set -o pipefail
set -o nounset


# from https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox
MELLANOX_PUBLIC_KEY="\
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2.0.14 (GNU/Linux)

mQGiBFMEmE0RBACsz1qcFsYOs0LHy/pBR2ip0gnHYbZgLy00R2i7cELxmqGcESzp
6IfzIdwOX9oVsPI6NT/yvftp+BxALuD8UC52MLjdMJZ+1sXBZM4J5xnDmQMhIp0G
wCse8usM8Zad1WTKq+P0ip8Gd17WEpfwMQPKXg3npcF69zaz/ceeDavqjwCgofU0
rb8ui7cZs+c+7U+5mrXxmcMD/R/tV8tEykQFW7PKuZ9NvvRX2XFuQD9LZRW7v+Rg
ebC0GAM1ZSqgI7uNUL3ZLAMgxaURLZViqKPgiw8373uoayfrnccttoZ2prHdtB5O
ZPo9vp8wJYUd+Wug2c1nuzXQtTrs/wfeJDn/PfvlEIGlXYPphsBXGQd7MbMLtW7g
u6h/A/9lmSP1fFQflTRlO5j3jXrlFkW05lMlWVZD3H75obQxHlM7eGCgnUPABBMt
aoZDZDf5P9I3xinu9qhDi7Vbz7QOkWOGr2dHLUOMqIgoKz7zRcFtbAl65AcOuEKu
KpLE/R3mRjZ7vrCPud6euEKGpvMbdevDF7GeMG3fcvVlK1ivy7RVTWVsbGFub3gg
VGVjaG5vbG9naWVzIChNZWxsYW5veCBUZWNobm9sb2dpZXMgLSBTaWduaW5nIEtl
eSB2MikgPHN1cHBvcnRAbWVsbGFub3guY29tPohiBBMRAgAiBQJTBJhNAhsDBgsJ
CAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRDF7YPiYiTAUFcAAJ49FBA3hy0P0gsZ
q/ZkAMrgXZaG9wCcDjMtZZETG5NEaIVg3GYqJcvI4AW5AQ0EUwSYTRAEANmBQ0WP
O3VsOrDH0VX+fa1nuKpTqyPFmrROtiI0Ux1dEsU/hpFJnFHtv+CW8ppUlMmjhw6U
olS3dqvO+fWxe1FMLVpp1BQLI6udM5j/P1IEDH7TmZD5trYFp4PxXagKO2nBeqjj
NydQckgREntGCOGPqheBRdopmlJSPlTptQavAAMFA/9BVSpmStx3BsS0z5NPSI/V
wJFeQiXFq8zDKbEVHFMjYWGqbhGWDPaLJWxxNLF1hdpbZSQCAeaESNLYG0iqXwb6
6O79BHpGeN0AWyy2J6FJpt0zwlCDfx7fgpFKMGzIxXWiTDNmKon241ojgM1iYC2o
arjropoA0dtG6noS2KJBYIhJBBgRAgAJBQJTBJhNAhsMAAoJEMXtg+JiJMBQzxUA
oJ+aJ2l6vt1S1tIKCLVtDMH8liOBAJ45EQ867jkf6f2Anihx9XJ0LLKZvw==
=QMd9
-----END PGP PUBLIC KEY BLOCK-----
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2.0.14 (GNU/Linux)

mQGiBFIHkboRBADGcZ0FQvQl8frNzEZIep6D+KSZY/ps70+k3ZJ+wj2mvtGZSV9t
zeEUbte7ft5HzrIniB87j1Swp+mSJIomLTkOcQunoqCCHQkuPOEMi1urUmdjpyc7
nJjsQ63GLvH0DfmknGga4rCj3Kepn9mhJ9mqfS+/aXrz1ZP4Dk+alpi/RwCgplxo
94IruAMKoQCdJ3SmfqvszYcEAMUJ3qmCpYax4s/0XyX36emLiMioHZehq/QXdFmj
VmqqxL5QFmq9Yof8SwGBwpS8FS0VX8BTs7xAs5W7ZC7iGGo9uxuXZzeZ8vcwh6VX
OVmbtqLgXyPKqzHIDwJ8Q5Df0JQpRnCmQQaHbEcoOstSTP/3NHLFBIllPq7gqIpZ
9HQoBACvlwzvtabC9q1OAikXY5YKKbAtkmZYBa5I2qvfHV1bIRYPPHWW2shilX0N
Kz2pTR1ZlwEcz+CUhPtJgoWhkMu/Vl7NMeB0YzGmjQorHRj2mAvSbv/wvjeIMgbw
qRXIksGYiUSpTLtQYTfpJlNe0ZKzn6kHbqGUYZ92Jx2ki3gQqbQsTWVsbGFub3gg
VGVjaG5vbG9naWVzIDxzdXBwb3J0QG1lbGxhbm94LmNvbT6IYgQTEQIAIgUCUgeR
ugIbAwYLCQgHAwIGFQgCCQoLBBYCAwECHgECF4AACgkQAQSPp6nktkPsXwCfW2Rn
pgmC4zLTMBRo/hKsIvag2ToAnAtlzxpMAZGUQHBODfpGqx7MyHmUuQENBFIHkboQ
BADd2OqEdSDCB6KkgZ2BjURxpiDbZxEAEsTJOUBFMPSqdJN0GcqUon5Hc3yADDOF
ztdWf5XCKSp/loYvjTYM21Qq20g5EB2SU9FU6Eoq5vyU/HS3/c1wjiYv2rjMll62
kc4oqRkM/fp9crrjArssfqMQcQRVYBS3dYdmoVdpHEH68wADBQP/XPW9r3wwGvUr
7hlFskYrSC/8s3r7vB4/mcF6UMkM4xEaP3jq8HH0SLkLbcPTa1+C/5evhmLbT12f
dub/V0/JVT9YsxS3anmvefT6EXjUntYXDLPhhRJqUCnxYjf95FX5zxudB5gMEwLh
9pmRMgqMCDsIANVv7V77DagfaWNkhqSISQQYEQIACQUCUgeRugIbDAAKCRABBI+n
qeS2Q71kAJ45i6YdS9bZGR8tDI0NfneMiU32CwCfdje+fgX5gUtag5SshjxyMrgt
DgY=
=z9pR
-----END PGP PUBLIC KEY BLOCK-----
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQENBFpbc0cBCADDST+ekKD1YJje77oDX94gRolmUlh0df4n6/xvE700M1vPAiTT
kU3WJcvwnuTZpyMGSsAQCXXQRJuQObnkPEvjVAPgh8fvghCXgVElcr6dqXu3EVze
iCkdYm08t/+FF3kg/P6VYPjgEM/GIFnKTz37LrQlUM4ArG0ENIYM9xjurnKWuV9r
JuckJcUsmZUS/D9QMM2fuurYOEWHrE8t+n2EcO4aoY2x0ogYce0vON539rJiskjz
OPhIB9G7ZFQabQnyxzEKiUUDyJsbe38XDT4eyjUR2mlHGgTY/WzGdDEtIKRBWsd3
TV3wXt42nF9YA3oieeaTbIluyywNnOj1vyT1ABEBAAG0VU1lbGxhbm94IFRlY2hu
b2xvZ2llcyAoTWVsbGFub3ggVGVjaG5vbG9naWVzIC0gU2lnbmluZyBLZXkgdjMp
IDxzdXBwb3J0QG1lbGxhbm94LmNvbT6JATcEEwEIACEFAlpbc0cCGwMFCwkIBwMF
FQoJCAsFFgIDAQACHgECF4AACgkQoCT28ObWooFXYwgAunwBFELGlwKonnmnbi4/
avUa8e0wRpww//DJjI0HQWjMk7oPLDbS50CVps1Mu0SxBAPYGtsFeSH6UMC6A0K4
yoxXICVl409vYkycNu/vq6eLTbM2Y0PFvBDzRAf3rJXL0ApLuUb57ARZvc7Np7LA
v8K53PdOJUEFns8Ipp+2puEVx5dfezm7LwRca6ohoLUEdI/PobmGUeNvO5dvfiix
LvSVw2A2awihB7dcs5cpo57VxBWPs7+sYBZ0+EUJbtQEiHAyPvKs29nMeaCIwPTd
88A5RrhsEJx+QWXuG6NA4rfehy5e9j1PW3XnC2fMl6w7gNLY5I8Vq6c2MJ73NZ6y
wLkBDQRaW3NHAQgAynkQ+mf4f5cdM4/bJuRWlPxxuN3CUxN9Q6B5B1/13p6tkydP
C7S4ro8H8sSlO5FbbxihfZLPTbFNrBkd///OQYMJW/slbtT6D9dYmCIeuHObMEMb
V+Bn1bWQId2vZgr0+m0Xe3K+KqhsylsrmC1ebShMnny/V+MlOQQt+L089BNiyCB4
70mhgM1NiJFv9EOQlXWWaMqWTxZGYkdOuFW0q8NnSGOqI5xjrAUxaHZ/1U3yPy0k
eAjX1AKJngaj86SvIzEefxq4oA2gZ8UFVO/qFH5OhfoovrEwudJEuIgGb76XOb9m
AoZlAqQLJniC97ld515ivBdSi4SZkaFbypnX4QARAQABiQEfBBgBCAAJBQJaW3NH
AhsMAAoJEKAk9vDm1qKBHhMIAJuGbb6S3nb2xAD3GjB8F2xNcZxWQ+Qz70DY5vV/
WhrJl7cknXMxsbWvQupuYk6LujZraG9YoD4csZ5o+k3s3BGKVUXdZdhjaHpcAa5F
X12ADLHca5mlmdCaaORYXQ+xHYRlOKas4I6LPpZ79BauVomEnPcv/bL0kGFzDvLr
K3RdQ1n/pbcWcxxSY3InphAnslLUg0PTAME6Yay5F7WrJsnZnXApUjOlZvlPIl2c
iplivN8o85eBKQXvYRg/c5iyc0koTmkM6OXNvUy0hV9z8WhhK9O+ApXwMUMf43DS
KOIg9RxhZFQoPXptaQZDLz89sWmZaiXsyBPJyjlmaTjwHGM=
=Iy5R
-----END PGP PUBLIC KEY BLOCK-----
"


InstallSSH() {
  # for mpirun
  rm -rf  /root/.ssh
  mkdir /root/.ssh || true
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
  cat ~/.ssh/id_ed25519.pub >>~/.ssh/authorized_keys

  sed -i 's/[ #]\(.*StrictHostKeyChecking \).*/ \1no/g' /etc/ssh/ssh_config
  echo "    UserKnownHostsFile /dev/null" >>/etc/ssh/ssh_config
  sed -i 's/#\(StrictModes \).*/\1no/g' /etc/ssh/sshd_config
}

InstallOfedRepo() {
  # required by perftest
  echo " install ofed lib"
  apt-get update
  
  # Mellanox OFED (latest)
  #wget -qO - https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox | apt-key add -
  echo "${MELLANOX_PUBLIC_KEY}" | apt-key add -

  cd /etc/apt/sources.list.d/
  wget --no-check-certificate ${ENV_DOWNLOAD_OFED_DEB_SOURCE}
  apt-get update

  for ITEM in "infiniband-diags" "rdmacm-utils" "ibverbs-utils"; do
    VERSION=$(apt-cache show ${ITEM} | grep Version | grep mlnx | awk '{print $2}')
    [ -n "${VERSION}" ] || {
      echo "error, failed to find mlnx version "
      exit 1
    }
    apt-get install -y --no-install-recommends ${ITEM}=${VERSION}
  done

}


packages=(
  iproute2
  smc-tools
  lshw
  #lspci
  pciutils
  vim
  iperf3
  # ping
  iputils-ping
  arping
  dnsutils
  # ssh server
  openssh-server
  curl
  jq
  inxi
  hwloc
  libgomp1
  kmod
  ethtool
  iptables
  #--------------
  libibverbs-dev
  libibumad3
  libibumad-dev
  librdmacm-dev
  # ibdiagnet ibnetdiscover
  ibutils2
  ibdump
  libelf1
  libltdl7
  libnuma1
  psmisc
)

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends wget gnupg2

# tzdata is one of the dependencies and a timezone must be set
# to avoid interactive prompt when it is being installed
ln -fs /usr/share/zoneinfo/UTC /etc/localtime

InstallOfedRepo
apt-get install -y --no-install-recommends "${packages[@]}"
InstallSSH

apt-get purge --auto-remove
apt-get clean
rm -rf /var/lib/apt/lists/*
