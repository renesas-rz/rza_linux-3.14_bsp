#!/bin/bash
# Will be run automatically by build.sh
# Please edit the settings below if you don't want to use the defaults

# When calling this script, an enviroment variable 'ROOTDIR' must be set
# to contain a full path.
if [ "$ROOTDIR" == "" ]; then
  echo -e "
ERROR: You must set ROOTDIR before calling this file.
   If you want to use this file without build.sh, then
   you could pass it on the same line like:

      $ export ROOTDIR=$(pwd) ; source ./setup_env.sh

"
  exit
fi

# Settings
export OUTDIR=${ROOTDIR}/output
export TOOLCHAIN_DIR=$OUTDIR/gcc-linaro-arm-linux-gnueabihf-4.8-2014.02_linux
export BUILDROOT_DIR=$OUTDIR/buildroot-2014.05


export PATH=${TOOLCHAIN_DIR}/bin:$PATH
export CROSS_COMPILE="arm-linux-gnueabihf-"
export ARCH=arm

echo "Build Environment set"
export ENV_SET=1


