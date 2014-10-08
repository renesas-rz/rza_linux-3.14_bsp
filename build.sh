#!/bin/bash

# Function: usage
function usage {
  echo -ne "\033[1;31m" # RED TEXT
  echo -e "\nWhat do you want to build?"
  echo -ne "\033[00m" # END TEXT COLOR
  echo -e "    ./build.sh get_toolchain"
  echo -e "    ./build.sh kernel"
  echo -e "    ./build.sh u-boot"
  echo -e "    ./build.sh buildroot"
  echo -e "    ./build.sh librzjpeg"
  echo -e ""
  echo -e "  You may also do things like:"
  echo -e "    ./build.sh kernel menuconfig"
  echo -e "    ./build.sh buildroot menuconfig"
}

# Function: banner_color
function banner_yellow {
  echo -ne "\033[1;33m" # YELLOW TEXT
  echo "============== $1 =============="
  echo -ne "\033[00m"
}
function banner_red {
  echo -ne "\033[1;31m" # RED TEXT
  echo "============== $1 =============="
  echo -ne "\033[00m"
}
function banner_green {
  echo -ne "\033[1;32m" # GREEN TEXT
  echo "============== $1 =============="
  echo -ne "\033[00m"
}


###############################################################################
# script start
###############################################################################

# Save current directory
ROOTDIR=`pwd`

# Check command line
if [ "$1" == "" ] ; then
  usage
  exit
fi

# Run build environment setup
if [ "$ENV_SET" != "1" ] ; then
  # Because we are using 'source', ROOTDIR can be seen in setup_env.sh
  source ./setup_env.sh
fi

# Create output build directory
if [ ! -e $OUTDIR ] ; then
  mkdir -p $OUTDIR
fi

###############################################################################
# get_toolchain
###############################################################################
if [ "$1" == "get_toolchain" ] ; then
  banner_yellow "Downloading Linaro toolchain for ARM"

  cd $OUTDIR

  # Download toolchain
  if [ ! -e gcc-linaro-arm-linux-gnueabihf-4.8-2014.02_linux.tar.xz ] ;then
    wget http://releases.linaro.org/14.02/components/toolchain/binaries/gcc-linaro-arm-linux-gnueabihf-4.8-2014.02_linux.tar.xz
  fi

  # extract toolchain
  if [ ! -e gcc-linaro-arm-linux-gnueabihf-4.8-2014.02_linux ] ;then
    echo "extracting toolchain..."
    tar -xf gcc-linaro-arm-linux-gnueabihf-4.8-2014.02_linux.tar.xz
  fi

  cd $ROOTDIR
fi

##### Check if we have all the host tools we need #####
CHECK=$(which mkimage)
if [ "$CHECK" == "" ] ; then
  banner_red "mkimage is not installed"
  echo -e "You need the program mkimage installed in order to build a kernel uImage."
  echo -e "In Ubuntu, you can install it by running:\n\tsudo apt-get install u-boot-tools\n"
  echo -e "Existing build script.\n"
  exit
fi

##### Check if we have all the host tools we need #####
CHECK=$(which ncurses5-config)
if [ "$CHECK" == "" ] ; then
  banner_red "ncurses is not installed"
  echo -e "You need the package ncurses installed in order to use menuconfig."
  echo -e "In Ubuntu, you can install it by running:\n\tsudo apt-get install ncurses-dev\n"
  echo -e "Existing build script.\n"
  exit
fi

##### Check if toolchain is installed correctly #####
CHECK=$(which arm-linux-gnueabihf-gcc)
if [ "$CHECK" == "" ] ; then
  # Toolchain not found in path...so nothing is going to work.
  banner_red "Toolchain not installed correctly"
  echo -e "Either run \"./build.sh get_toolchain\" first, or edit the setup_env.sh accordingly"
  echo -e "Existing build script.\n"
  exit
fi


###############################################################################
# build kernel
###############################################################################
if [ "$1" == "kernel" ] ; then
  banner_yellow "Building kernel"

  cd $OUTDIR

  # Download linux-3.14
  if [ ! -e linux-3.14.tar.xz ] ;then
    wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.14.tar.xz
  fi

  # extract linux-3.14
  if [ ! -e linux-3.14 ] ;then
    echo "extracting kernel..."
    tar -xf linux-3.14.tar.xz
  fi

  cd linux-3.14

  # Patch kernel
  if [ ! -e arch/arm/configs/rskrza1_defconfig ] ;then
    # Combine all the patches, then patch at once
    cat $ROOTDIR/patches-kernel/* > /tmp/kernel_patches.patch
    patch -p1 -i /tmp/kernel_patches.patch

    # Configure Kernel
    make rskrza1_defconfig
  fi

  # Build kernel
  if [ "$2" == "" ] ;then
    # By default, build uImage
    make -j4 uImage
    make -j4 dtbs

    if [ ! -e vmlinux ] ; then
      # did not build, so exit
      banner_red "Kernel Build failed. Exiting build script."
      exit
    else
      banner_green "Kernel Build Successful"
    fi
  else
      # user wants to build something special
      banner_yellow "Custom Build"
      echo -e "make -j4 $2 $3 $4\n"
      make -j4 $2 $3 $4
  fi

  cd $ROOTDIR
fi

###############################################################################
# build u-boot
###############################################################################
if [ "$1" == "u-boot" ] ; then
  banner_yellow "Building u-boot"

  cd $OUTDIR

  # Download u-boot-2013.04.tar.bz2
  if [ ! -e u-boot-2013.04.tar.bz2 ] ;then
    wget http://ftp.denx.de/pub/u-boot/u-boot-2013.04.tar.bz2
  fi

  # extract u-boot-2013.04
  if [ ! -e u-boot-2013.04 ] ;then
    echo "extracting u-boot..."
    tar -xf u-boot-2013.04.tar.bz2
  fi

  cd u-boot-2013.04

  # Patch u-boot
  if [ ! -e include/configs/rskrza1.h ] ;then
    # Combine all the patches, then patch at once
    cat $ROOTDIR/patches-uboot/* > /tmp/uboot_patches.patch
    patch -p1 -i /tmp/uboot_patches.patch

    # Configure u-boot
    make rskrza1_config
  fi

  # Build u-boot
  if [ "$2" == "" ] ;then

    # default build
    make

    if [ ! -e u-boot.bin ] ; then
      # did not build, so exit
      banner_red "u-boot Build failed. Exiting build script."
      exit
    else
      banner_green "u-boot Build Successful"
    fi
  else
      # user wants to build something special
      banner_yellow "Custom Build"
      echo -e "make $2 $3 $4\n"
      make $2 $3 $4
  fi

  cd $ROOTDIR

fi

###############################################################################
# build buildroot
###############################################################################
if [ "$1" == "buildroot" ] ; then
  banner_yellow "Building buildroot"

  cd $OUTDIR

  # Download buildroot-2014.05.tar.bz2
  if [ ! -e buildroot-2014.05.tar.bz2 ] ;then
    wget http://buildroot.uclibc.org/downloads/buildroot-2014.05.tar.bz2
  fi

  # extract buildroot-2014.05
  if [ ! -e buildroot-2014.05 ] ;then
    echo "extracting buildroot..."
    tar -xf buildroot-2014.05.tar.bz2
  fi

  cd buildroot-2014.05

  # Patch and Configure Buildroot for the RSKRZA1
  if [ ! -e configs/rskrza1_defconfig ]; then
    # Copy in our rootfs_overlay directory
    mkdir -p output
    cp -a $ROOTDIR/patches-buildroot/rootfs_overlay output

    # Copy in our default Buidlroot config for the RSK
    # NOTE: It was made by running this inside buildroot
    #   make savedefconfig BR2_DEFCONFIG=../rskrza1_defconfig
    # or rather
    #   ./build.sh buildroot savedefconfig BR2_DEFCONFIG=../rskrza1_defconfig
    #          NOTE: 'BR2_PACKAGE_JPEG=y' had to be manually added before
    #                'BR2_PACKAGE_JPEG_TURBO=y'
    #
    cp -a $ROOTDIR/patches-buildroot/rskrza1_defconfig configs

    # Specify the location of our toolchain (to avoid having to download it again)
    # by changing out the default value in our rskrza1_defconfig 
    sed -i "s%^BR2_TOOLCHAIN_EXTERNAL_PATH=.*\$%BR2_TOOLCHAIN_EXTERNAL_PATH=\"$TOOLCHAIN_DIR\"%" configs/rskrza1_defconfig

    # Select our RSKRZA1 config
    make rskrza1_defconfig
  fi

  # Build Buildroot
  if [ "$2" == "" ] ;then

    # default build
    make

    if [ ! -e output/images/rootfs.tar ] ; then
      # did not build, so exit
      banner_red "Buildroot Build failed. Exiting build script."
      exit
    else
      banner_green "Buildroot Build Successful"
    fi
  else
      # user wants to build something special
      banner_yellow "Custom Build"
      echo -e "make $2 $3 $4 $5\n"
      make $2 $3 $4 $5
  fi

  cd $ROOTDIR
fi

###############################################################################
# build librzjpeg
###############################################################################
if [ "$1" == "librzjpeg" ] ; then
  banner_yellow "Building librzjpeg"

  cd $OUTDIR

  # Requries Buildroot to be already built (because we need the libraries from
  # jpeg-8d)

  if [ ! -e $BUILDROOT_DIR/output/build/jpeg-turbo-1.3.1 ]; then
    banner_red "Buildroot Required"
    echo "The package jpeg-turbo-1.3.1 needs to be built first so we can link against"
    echo "the libraries".
    exit
  fi

  # extract buildroot-2014.05
  if [ ! -e librzjpeg ] ;then
    echo "extracting librzjpeg..."
    tar -xf $ROOTDIR/librzjpeg/librzjpeg.tar.xz
  fi

  cd librzjpeg

  if [ ! -e Makefile ] ; then

    # Use the automake package utilites that Buildroot built already
    # so we don't require anyone to install it system wide.
    #autoreconf -vif
    $BUILDROOT_DIR/output/host/usr/bin/autoreconf -vif

    TOOLCHAIN=arm-linux-gnueabihf
    PREFIX=`pwd`/_install

    # Optional Debug info while running.
    #  ADD_DEBUG=-DSHJPEG_DEBUG

    ./configure --host=$TOOLCHAIN --prefix="$PREFIX" \
	CPPFLAGS="-I$BUILDROOT_DIR/output/staging/usr/include $ADD_DEBUG" \
	LDFLAGS="-L$BUILDROOT_DIR/output/staging/usr/lib"
  fi

  # Build librzjpeg
  make

  # Copy results to Buildroot overlay
  mkdir -p $BUILDROOT_DIR/output/rootfs_overlay/lib
  cp src/.libs/librzjpeg.so* $BUILDROOT_DIR/output/rootfs_overlay/lib
  mkdir -p $BUILDROOT_DIR/output/rootfs_overlay/root/bin
  cp tests/.libs/rzjpegtest $BUILDROOT_DIR/output/rootfs_overlay/root/bin

  # Copy in startup script (that will map our /dev/uio device for us)
  mkdir -p $BUILDROOT_DIR/output/rootfs_overlay/etc
  cp -a $ROOTDIR/librzjpeg/etc/* $BUILDROOT_DIR/output/rootfs_overlay/etc

  if [ ! -e src/.libs/librzjpeg.so ] ; then
    # did not build, so exit
    banner_red "librzjpeg Build failed. Exiting build script."
    exit
  else
    banner_green "librzjpeg Build Successful"
  fi

  echo " "
  banner_yellow "Please re-run buildroot to add to rootfs image"
  echo -n "Do you want to re-run buildroot now? [y/n]: "
  read answer
  if [ "$answer" == "y" ];then
    banner_yellow "Rebuilding Buildroot"
    cd $BUILDROOT_DIR
    make
    banner_green "Rebuilding Buildroot Complete"
  fi

  cd $ROOTDIR
fi

