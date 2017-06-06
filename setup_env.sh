#!/bin/bash
# Will be run automatically by build.sh
# Please edit the settings below if you don't want to use the defaults

# When calling this script, an enviroment variable 'ROOTDIR' must be set
# to contain a full path.
if [ "$ROOTDIR" == "" ]; then
  echo -e '
ERROR: You must set ROOTDIR before calling this file.
   If you want to use this file without build.sh, then
   you could pass it on the same line like:

      $ export ROOTDIR=$(pwd) ; source ./setup_env.sh

'
  exit
fi

# Settings
export OUTDIR=${ROOTDIR}/output

# As of GCC 4.9, you can now get a colorized output
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Buildroot directory
if [ -e $OUTDIR/br_version.txt ] ; then
  source $OUTDIR/br_version.txt
fi
export BUILDROOT_DIR=$OUTDIR/buildroot-$BR_VERSION

# Toolchain directory (for u-boot and kernel)
if [ -e $OUTDIR/buildroot-$BR_VERSION/output/host ] ; then

  export TOOLCHAIN_DIR=$OUTDIR/host/usr

  # set toolchain prefix and add to path
  cd $OUTDIR/buildroot-$BR_VERSION/output/host/usr/bin
  export CROSS_COMPILE=`ls *gnueabi*-gcc | sed 's/gcc//'`
  export PATH=`pwd`:$PATH
  cd -
  export ARCH=arm
fi


# -------------------------------------------------
# Change prompt to inform the BSP env has been set
# -------------------------------------------------
# Uncomment the prompt you want

# Change prompt to (rza1_bsp)
#PS1="(rza1_bsp)$ "

# Change prompt to (rza1_bsp) with RED text
#PS1="\[\e[1;31m\](rza1_bsp)$\[\e[00m\] "

# Change prompt to (rza1_bsp) with RED text
# with current directory printed out on the line above
#PS1="dir: \w\n\[\e[1;31m\](rza1_bsp)$\[\e[00m\] "

# Change prompt to (rza1_bsp) with RED text
# with current directory printed out on the line above in ORANGE text
PS1="\[\e[33m\]dir: \w\n\[\e[1;31m\](rza1_bsp)$\[\e[00m\] "


echo "Build Environment set"
export ENV_SET=1


