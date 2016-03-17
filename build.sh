#!/bin/bash

# Function: usage
function usage {
  echo -ne "\033[1;31m" # RED TEXT
  echo -e "\nWhat do you want to build?"
  echo -ne "\033[00m" # END TEXT COLOR
  echo -e "    ./build.sh get_toolchain           : Downloads pre-built Linaro toolchain for ARM"
  echo -e "    ./build.sh kernel                  : Builds Linux kernel. Default is to build uImage"
  echo -e "    ./build.sh u-boot                  : Builds u-boot"
  echo -e "    ./build.sh buildroot               : Builds Root File System"
  echo -e "    ./build.sh librzjpeg               : RZ/A1 JPEG HW decode example application"
  echo -e "    ./build.sh axfs                    : Builds an AXFS image from the last Buildroot output"
  echo -e ""
  echo -e "    ./build.sh env                     : Set up the Build environment so you can run 'make' directly"
  echo -e ""
  echo -e "    ./build.sh jlink                   : Downlaod a binary image to RAM so you can program it into QSPI"
  echo -e ""
  echo -e "  You may also do things like:"
  echo -e "    ./build.sh kernel menuconfig       : Open the kernel config GUI to enable options/drivers"
  echo -e "    ./build.sh kernel rskrza1_xip_defconfig : Switch to XIP version of the kernel"
  echo -e "    ./build.sh kernel xipImage         : Build the XIP kernel image"
  echo -e "    ./build.sh buildroot menuconfig    : Open the Buildroot config GUI to select additinal apps to build"
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

# Find out how many CPU processor cores we have on this machine
# so we can build faster by using multithreaded builds
NPROC=2
if [ "$(which nproc)" != "" ] ; then  # make sure nproc is installed
  NPROC=$(nproc)
fi
BUILD_THREADS=$(expr $NPROC + $NPROC)

###############################################################################
# env
###############################################################################
if [ "$1" == "env" ] ; then
  echo "Copy/paste this line and execute it in your command window."
  echo ""
  echo 'export ROOTDIR=$(pwd) ; source ./setup_env.sh'
  echo ""
  echo "Then, you can execute 'make' directly in u-boot, linux, buildroot, etc..."
  exit
fi

###############################################################################
# jlink
###############################################################################
if [ "$1" == "jlink" ] ; then
  echo "Download binary files to on-board RAM"

  if [ "$2" == "" ] ; then
    echo "
usage: ./build.sh jlink {FILE} {ADDRESS}
   FILE: The path to the file to download.
ADDRESS: (Optional) Default is 0x08000000 (begining of SDRAM)

Examples:
  # u-boot
  ./build.sh jlink output/u-boot-2015.01/u-boot.bin

  # Device Tree Blob
  ./build.sh jlink output/linux-3.14/arch/arm/boot/dts/r7s72100-rskrza1.dtb

  # Kernel
  ./build.sh jlink output/linux-3.14/arch/arm/boot/uImage
  ./build.sh jlink output/linux-3.14/arch/arm/boot/xipImage

  # Root File System
  ./build.sh jlink output/buildroot-2014.05/output/images/rootfs.squashfs
  ./build.sh jlink output/axfs/rootfs.axfs.bin

NOTE: Your board should be up and running in u-boot first before executing this command.

"
    exit
 fi

  # File check
  if [ ! -e "$2" ] ; then
    echo "ERROR: File does not exist. $2"
    exit
  fi

  filename=$(basename "$2")
  extension="${filename##*.}"
  #filename_only="${filename%.*}"

  # Jlink must have a file extension of .bin for downloading
  if [ "$extension" == "bin" ] ; then
    dlfile=/tmp/$filename
  else
    dlfile=/tmp/$filename.bin
  fi
  cp -v "$2" $dlfile

  ramaddr=$3
  if [ "$ramaddr" == "" ] ; then
    ramaddr="0x08000000"
  fi

  # Create a jlink script and execute it
  echo "loadbin $dlfile,$ramaddr" > /tmp/jlink_load.txt
  echo "g" >> /tmp/jlink_load.txt
  echo "exit" >> /tmp/jlink_load.txt

  # After version 5.10, a new command line option is needed
  CHECK=`which JLinkExe`
  JLINKPATH=$(readlink -f $CHECK | sed 's:/JLinkExe::')
  JLINKVER=$(ls $JLINKPATH/libjlinkarm.so.5.* | sed "s:$JLINKPATH/libjlinkarm.so.::")
  # Since version numbers are not really 'numbers', we'll use 'sort' to figure
  # out what one is the smallest, and if 5.10 is still the first number in the list,
  # then we know the current version is either the same or later
  ORDER=$(echo -e "5.10\\n$JLINKVER" | sort -V)
  if [ "${ORDER:0:4}" == "5.10" ] ; then
    JTAGCONF='-jtagconf -1,-1'
  fi

  JLinkExe -speed 15000 -if JTAG $JTAGCONF -device R7S721001 -CommanderScript /tmp/jlink_load.txt

  echo "-----------------------------------------------------"
  echo -en "\tFile size was:\n\t"
  du -h $dlfile
  echo "-----------------------------------------------------"

FILESIZE=$(cat $dlfile | wc -c)

  CHECK=$(echo $dlfile | grep u-boot)
  if [ "$CHECK" != "" ] ; then
  echo "Example program operations:

# Rewrite u-boot (512 KB):
=> sf probe 0 ; sf erase 0 80000 ; sf write $ramaddr 0 80000
"
  exit
  fi

  CHECK=$(echo $dlfile | grep dtb)
  if [ "$CHECK" != "" ] ; then
  echo "Example program operations:

# Program DTB (32 KB)
=> sf probe 0 ; sf erase C0000 40000 ; sf write $ramaddr C0000 8000
"
  exit
  fi

  CHECK=$(echo $dlfile | grep Image)
  if [ "$CHECK" != "" ] ; then
  echo "Example program operations:

# Program Kernel (5MB max, Dual SPI flash)
=> sf probe 0:1 ; sf erase 100000 280000 ; sf write $ramaddr 100000 500000

# Program Kernel (X MB size, Dual SPI Flash)
=> setenv e_sz 280000 ; setenv w_sz 500000
=> sf probe 0:1 ; sf erase 100000 \${e_sz} ; sf write $ramaddr 100000 \${w_sz}
"
  exit
  fi

  CHECK=$(echo $dlfile | grep rootfs)
  if [ "$CHECK" != "" ] ; then
  echo "Example program operations:

"
	# Program rootfs (Dual Flash memory)
	if [ $FILESIZE -le $((0x400000)) ]; then	# <= 4MB?
	  echo "Program Rootfs (4MB)
  => sf probe 0:1 ; sf erase 00400000 200000 ; sf write $ramaddr 00400000 400000"
	elif [ $FILESIZE -le $((0x600000)) ]; then	# <= 6MB?
	  echo "Program Rootfs (6MB)
  => sf probe 0:1 ; sf erase 00400000 300000 ; sf write $ramaddr 00400000 600000"
	elif [ $FILESIZE -le $((0x800000))  ]; then	# <= 8MB?
	  echo "Program Rootfs (8MB)
  => sf probe 0:1 ; sf erase 00400000 400000 ; sf write $ramaddr 00400000 800000"
	elif [ $FILESIZE -le $((0x800000))  ]; then	# <= 10MB?
	  echo "Program Rootfs (10MB)
  => sf probe 0:1 ; sf erase 00400000 500000 ; sf write $ramaddr 00400000 A00000"
	elif [ $FILESIZE -le $((0x800000))  ]; then	# <= 12MB?
	  echo "Program Rootfs (12MB)
  => sf probe 0:1 ; sf erase 00400000 600000 ; sf write $ramaddr 00400000 C00000"
	elif [ $FILESIZE -le $((0x800000))  ]; then	# <= 14MB?
	  echo "Program Rootfs (14MB)
  => sf probe 0:1 ; sf erase 00400000 700000 ; sf write $ramaddr 00400000 E00000"
	fi
  exit
  fi

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

  if [ "$2" == "" ] ; then
    echo " "
    echo "What do you want to build?"
    echo "For example:  (case sensitive)"
    echo " Traditional kernel:  ./build.sh kernel uImage"
    echo "         XIP kernel:  ./build.sh kernel xipImage"
    echo "  Kernel config GUI:  ./build.sh kernel menuconfig"
    exit
  fi

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

  fi

  IMG_BUILD=0
  # Build kernel
  if [ "$2" == "uImage" ] ;then
    IMG_BUILD=1
    if [ ! -e .config ] ; then
      # Need to configure kernel first
      make rskrza1_defconfig
    fi
  fi
  if [ "$2" == "xipImage" ] ;then
    IMG_BUILD=1
    if [ ! -e .config ] ; then
      # Need to configure kernel first
      make rskrza1_xip_defconfig
    fi
  fi

  if [ "$IMG_BUILD" == "1" ] ; then
    # NOTE: We have to make the Device Tree Blobs too, so we'll add 'dtbs' to
    #       the command line
    echo -e "make -j$BUILD_THREADS $2 dtbs\n"
    make -j$BUILD_THREADS $2 dtbs

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
      echo -e "make -j$BUILD_THREADS $2 $3 $4\n"
      make -j$BUILD_THREADS $2 $3 $4
  fi

  cd $ROOTDIR
fi

###############################################################################
# build u-boot
###############################################################################
if [ "$1" == "u-boot" ] ; then
  banner_yellow "Building u-boot"

  cd $OUTDIR

  # Download u-boot-2015.01.tar.bz2
  if [ ! -e u-boot-2015.01.tar.bz2 ] ;then
    wget ftp://ftp.denx.de/pub/u-boot/u-boot-2015.01.tar.bz2
  fi

  # extract u-boot-2015.01
  if [ ! -e u-boot-2015.01 ] ;then
    echo "extracting u-boot..."
    tar -xf u-boot-2015.01.tar.bz2
  fi

  cd u-boot-2015.01

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
  if [ ! -e buildroot-2014.05/README ] ;then
    echo "extracting buildroot..."
    tar -xf buildroot-2014.05.tar.bz2
  fi

  cd buildroot-2014.05

  # Patch and Configure Buildroot for the RSKRZA1
  if [ ! -e configs/rskrza1_defconfig ]; then
    # Copy in our rootfs_overlay directory
    mkdir -p output
    cp -a $ROOTDIR/patches-buildroot/rootfs_overlay output

    # Ask the user if they want to use the glib based Linaro toolchain
    # or build a uclib toolchain from scratch.
    banner_yellow "Toolchain selection"
    #echo -e "\n\n[ Toolchain selection ]"
    echo -e "What toolchain and C Library do you want to use for building applications?"
    echo "1) The pre-built Linareo toolchain (with glibc)"
    echo "       - This was the toolchain you already downloaded and used to build the"
    echo "         Linux kernel. It contains the standard gblic Libary."
    echo "2) A uClibc based toolchain built from open source"
    echo "       - This will use Buildroot to go out and download all the source"
    echo "         code needed to build a full gcc/uClibc based ARM toolchain."
    echo "         While this will create a smaller footprint file system,"
    echo "         it will take a very long to build the first time."
    for i in 1 2 3 ; do
      echo -n " Enter your choice (1 or 2): "
      read ANSWER
      if [ "$ANSWER" == "1" ] ; then break; fi
      if [ "$ANSWER" == "2" ] ; then break; fi
      TRY=$i
    done

    if [ "$TRY" == "5" ] ; then
      echo -e "\nI give up! I have no idea what you want to do."
      exit
    fi

    # Copy in our default Buidlroot config for the RSK
    # NOTE: It was made by running this inside buildroot
    #   make savedefconfig BR2_DEFCONFIG=../../patches-buildroot/rskrza1_defconfig
    # or rather
    #   ./build.sh buildroot savedefconfig BR2_DEFCONFIG=../../patches-buildroot/rskrza1_defconfig
    #          NOTE: 'BR2_PACKAGE_JPEG=y' had to be manually added before
    #                'BR2_PACKAGE_JPEG_TURBO=y' (a bug in savedefconfig I assume)
    #
    if [ "$ANSWER" == "1" ] ; then
      # User wants to use and existing (downloaded) toolchain (glibc)
      cp -a $ROOTDIR/patches-buildroot/rskrza1_defconfig configs/rskrza1_defconfig

      # Specify the location of our toolchain (to avoid having to download it again)
      # by changing out the default value in our rskrza1_defconfig 
      sed -i "s%^BR2_TOOLCHAIN_EXTERNAL_PATH=.*\$%BR2_TOOLCHAIN_EXTERNAL_PATH=\"$TOOLCHAIN_DIR\"%" configs/rskrza1_defconfig
    else
      # User wants to build a uClibc based toolchain from scratch
      cp -a $ROOTDIR/patches-buildroot/rskrza1_defconfig_uclibc configs/rskrza1_defconfig
    fi

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

  echo "NOTE: Because this application requries a UIO driver that statically allocates"
  echo "1MB of RAM at boot, this JPEG HW example is not available in XIP systems at this time."
  echo "Press enter to contiue..."
  read dummy

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


###############################################################################
# build axfs
###############################################################################
if [ "$1" == "axfs" ] ; then
  banner_yellow "Building axfs"

  cd $OUTDIR

  if [ ! -e axfs/mkfs.axfs ] ; then
    mkdir -p axfs
    cd axfs
    #  Build mkfs.axfs from source
    #  cp -a ../../axfs/mkfs.axfs-legacy/mkfs.axfs.c .
    #  cp -a ../../axfs/mkfs.axfs-legacy/linux .
    #  cp -a ../../axfs/mkfs.axfs-legacy/Makefile .
    #  make

    # Just copy the pre-build version
    cp -a ../../axfs/mkfs.axfs-legacy/mkfs.axfs .
    cd ..
  fi

  cd axfs

  # NOTE: If the 's' attribute is set on busybox executable (which it is by default when
  #   Buildroot builds it), and the file owner is not 'root' (which it will not be because
  #   you were not root when you ran Buildroot) you can't boot and will jsut keep getting
  #   a "Permission denieded" message after the file system is mounted"
  chmod a-s $BUILDROOT_DIR/output/target/bin/busybox

  #./mkfs.axfs -s -a $BUILDROOT_DIR/output/target rootfs.axfs.bin
  ./mkfs.axfs -s -a ../buildroot-2014.05/output/target rootfs.axfs.bin

  if [ ! -e rootfs.axfs.bin ] ; then
    # did not build, so exit
    banner_red "axfs Build failed. Exiting build script."
    exit
  else
    banner_green "axfs Build Successful"
    echo -e "You can find your AXFS image to flash here:"
    echo -e "\t$(pwd)/rootfs.axfs.bin"
  fi

  cd $ROOTDIR
fi

