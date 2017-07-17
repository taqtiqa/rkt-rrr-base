#!/usr/bin/env bash
set -ex

# References:
# https://mark911.wordpress.com/2016/02/06/how-to-compile-and-install-wget-and-rstudio-server-from-source-code-via-github-in-ubuntu-14-04-lts-64-bit/
# https://github.com/rocker-org/rocker-versioned/blob/master/r-ver/3.4.1/Dockerfile#L44

R_VERSION=${R_VERSION:-3.4.1}
version="${R_VERSION}.1"
rname="rrr-base"
name="rkt-${rname}" #: r,littler,rserver no packages installed rkt-rrr-tidy: r,littler,rserver recommends and tidy packages, rkt-rrr-devel: r,littler,rserver recommends and tidy devel environment
dist="yakkety"
arch="amd64"
mirror="http://mirror.rackspace.com/ubuntu"
out=/tmp/r-aci #$(mktemp -d)

BUILD_AUTHOR="TAQTIQA LLC"
BUILD_EMAIL="admin@taqtiqa.com"
BUILD_ORG="taqtiqa.com"
BUILD_DATE=${BUILD_DATE:-}
ACI_PREFIX="${BUILD_ORG}/${name}"

LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
TERM=xterm

if [ "$EUID" -ne 0 ]; then
    echo "This script uses functionality which requires root privileges"
    exit 1
fi

ACBUILD="/opt/acbuild/bin/acbuild --debug"

# In the event of the script exiting, end the build
acbuildend() {
    export EXIT=$?
    $ACBUILD end && exit $EXIT
}
function check_tool {
if ! which $1; then
    echo "Get $1 and put it in your \$PATH" >&2;
    exit 1;
fi
}

MODIFY=${MODIFY:-""}
FLAGS=${FLAGS:-""}
IMG_NAME="${BUILD_ORG}/${name}"
IMG_VERSION=${version}
ACI_FILE=${name}-linux-amd64-${version}.aci

# Extract R source to folder that eventually is under the rootfs - see below
if [ ! -e ${out}/R-${R_VERSION} ]; then
  mkdir -p ${out}
  pushd ${out}
    ## Download source code
    #curl -O https://cran.r-project.org/src/base/R-3/R-${R_VERSION}.tar.gz
    ## Extract source code
    #tar -xf R-${R_VERSION}.tar.gz
    #rm R-${R_VERSION}.tar.gz
  popd
fi

#     libjpeg62-turbo \

PKG_LIST="aptitude \
    bash-completion \
    ca-certificates \
    file \
    fonts-texgyre \
    g++ \
    gfortran \
    gsfonts \
    libcurl3 \
    libicu57 \
    libjpeg-dev \
    libopenblas-dev \
    libpangocairo-1.0-0 \
    libpng16-16 \
    libreadline7 \
    libtiff5 \
    make \
    unzip \
    zip"

# xorg-dev
BUILDDEPS="aptitude \
    build-essential \
    curl \
    default-jdk \
    fort77 \
    gcc-multilib \
    gfortran \
    gobjc++ \
    libblas-dev \
    libbz2-dev \
    libcairo2-dev \
    libcurl4-openssl-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libicu-dev \
    libpcre3-dev \
    libpng-dev \
    libreadline-dev \
    libtiff5-dev \
    liblzma-dev \
    libx11-dev \
    libxt-dev \
    perl \
    tcl8.6-dev \
    tk8.6-dev \
    texinfo \
    texlive-extra-utils \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-latex-recommended \
    x11proto-core-dev \
    xauth \
    xfonts-base \
    xvfb \
    zlib1g-dev"

if [ ! -e basic_rootfs ]; then
    debootstrap --verbose --force-check-gpg --variant=minbase \
    --components=main,universe,multiverse,restricted --include="${PKG_LIST}" \
    --arch=${arch} $dist $out $mirror
    rm -rf ${out}/var/cache/apt/archives/*
    cp ./scripts/${rname}_build.sh ${out}/R-${R_VERSION}/${rname}_build.sh
    chmod +x ${out}/R-${R_VERSION}/${rname}_build.sh
    mv $out basic_rootfs
fi

#cp -r basic_rootfs rootfs

# Start the build with ACI bootstrapped above
$ACBUILD begin ./rootfs
trap acbuildend EXIT

# Name the ACI
$ACBUILD set-name ${IMG_NAME}

# Based on Turnley Linux base image of Debian (12 MB)
# rkt trust --prefix=tklx.org/base
#$ACBUILD dep add tklx.org/base:0.1.1

$ACBUILD label add version ${version}
$ACBUILD label add arch amd64
$ACBUILD label add os linux
$ACBUILD annotation add authors "${BUILD_AUTHOR} <${BUILD_EMAIL}>"

$ACBUILD set-user 0
$ACBUILD set-group 0
$ACBUILD environment add OS_VERSION ${dist}
#$ACBUILD mount add build-dir $BUILDDIR
#$ACBUILD mount add src-dir $SRC_DIR

#
# Set locale before installing dev tools
#
$ACBUILD run -- echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
$ACBUILD run -- locale-gen en_US.utf8
$ACBUILD run -- /usr/sbin/update-locale LANG=en_US.UTF-8

$ACBUILD run -- apt-get install -y aptitude
$ACBUILD run -- aptitude install --download-only --assume-yes --full-resolver --purge-unused --without-recommends $BUILDDEPS
$ACBUILD run -- aptitude install --assume-yes --full-resolver --purge-unused --without-recommends $BUILDDEPS

#
# Run install script and clean up temp files
#
wd=/home/hedge/RubymineProjects/psac/coreos-vagrant/rkt-aci/r-project/.acbuild/currentaci/rootfs
$ACBUILD run -- ls -la
$ACBUILD run --working-dir=/R-${R_VERSION} -- /bin/bash -c "eval /R-${R_VERSION}/${rname}_build.sh"
#$ACBUILD run -- /bin/sh /tmp/R-${R_VERSION}/${rname}_build.sh
$ACBUILD run -- rm -rf /tmp/*

## Install nginx
#$ACBUILD run apk add nginx
#
#$ACBUILD run --  apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
#$ACBUILD run --  /bin/sh -c 'echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" | tee -a /etc/apt/sources.list.d/10gen.list'
#$ACBUILD run --  apt-get update
#$ACBUILD run --  apt-get -y install apt-utils
#$ACBUILD run --  apt-get -y install mongodb-10gen

$ACBUILD run -- groupadd -g 1000 rstudio
$ACBUILD run -- useradd -u 1000 -g 1000 -d / -M rstudio
$ACBUILD set-user 1000
$ACBUILD set-group 1000

# Add a port for the mongo status page
$ACBUILD port add rserver tcp 8787

#Configure RServer and RSession
# https://support.rstudio.com/hc/en-us/articles/200552316-Configuring-the-Server
# Set the working directory the app will run in inside the container
$ACBUILD set-working-directory /.acbuild/currentaci/rootfs/tmp/R-${R_VERSION}/

## Add a mount point for files to serve
#$ACBUILD mount add html /usr/share/nginx/html
#
## Run nginx in the foreground
#$ACBUILD set-exec -- /usr/sbin/nginx -g "daemon off;"
## Run mongo
#$ACBUILD set-exec -- /usr/bin/mongod --config /etc/mongodb.conf
#$ACBUILD set-exec -- /usr/bin/strace -e chown /usr/bin/python3 -c "import os; print(os.openpty())"
#
# Run apache, and remain in the foreground
# $ACBUILD --debug set-exec -- /bin/sh -c "chmod 755 / && /usr/sbin/httpd -D FOREGROUND"
#
#$ACBUILD run --  rstudio-server verify-installation
#
## Run RStudio Server in the foreground
#$ACBUILD run -- rstudio-server start

# Cleanup build dependencies
# $ACBUILD run -- aptitude purge --assume-yes $BUILDDEPS \

# Some recurrences have been known
$ACBUILD run -- apt-get autoremove --purge -y
$ACBUILD run -- apt-get autoremove --purge -y
$ACBUILD run -- apt-get clean

if [ -z "$MODIFY" ]; then
  # Save the ACI
  $ACBUILD write --overwrite ${name}-${version}-linux-${arch}.aci
fi

# Sign ACI
#gpg2 --armor --export ${BUILD_EMAIL} >${BUILD_ORG}_public.asc
#rkt trust --prefix=${ACI_PREFIX} ./${BUILD_ORG}_public.asc
#gpg2 --yes --batch --armor \
#--output "${name}"-"${version}"-"${os}"-"${arch}".aci.asc \
#--detach-sign "${name}"-"${version}"-"${os}"-"${arch}".aci

if [ -e ${out}/tmp/ ]; then
  rm -rf ${out}/tmp/*
fi

$ACBUILD end