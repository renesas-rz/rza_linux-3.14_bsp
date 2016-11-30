#!/bin/bash

# Function: usage
function usage {
  echo -ne "\033[1;31m" # RED TEXT
  echo -e "\nWhat do you want to build?"
  echo -ne "\033[00m" # END TEXT COLOR
  echo -e "    ./build.sh buildroot               : Builds Root File System (and installs toolchain)"
  echo -e "    ./build.sh u-boot                  : Builds u-boot"
  echo -e "    ./build.sh kernel                  : Builds Linux kernel. Default is to build uImage"
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

##### Check if toolchain is installed correctly #####
function check_for_toolchain {
  CHECK=$(which ${CROSS_COMPILE}gcc)
  if [ "$CHECK" == "" ] ; then
    # Toolchain was found in path, so maybe it was hard coded in setup_env.sh
    return
  fi
  if [ ! -e $OUTDIR/br_version.txt ] ; then
    banner_red "Toolchain not installed yet."
    echo -e "Buildroot will download and install the toolchain."
    echo -e "Plesae run \"./build.sh buildroot\" first and select the toolchain you would like to use."
    exit
  fi
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

# Find out how many CPU processor cores we have on this machine
# so we can build faster by using multi-threaded builds
NPROC=2
if [ "$(which nproc)" != "" ] ; then  # make sure nproc is installed
  NPROC=$(nproc)
fi
BUILD_THREADS=$(expr $NPROC + $NPROC)

###############################################################################
# env
###############################################################################
if [ "$1" == "env" ] ; then

  check_for_toolchain

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
  ./build.sh jlink output/buildroot-$BR_VERSION/output/images/rootfs.squashfs
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
  if [ -e $JLINKPATH/libjlinkarm.so.5 ] ; then
    JLINKVER=$(ls $JLINKPATH/libjlinkarm.so.5.* | sed "s:$JLINKPATH/libjlinkarm.so.::")
    # Since version numbers are not really 'numbers', we'll use 'sort' to figure
    # out what one is the smallest, and if 5.10 is still the first number in the list,
    # then we know the current version is either the same or later
    ORDER=$(echo -e "5.10\\n$JLINKVER" | sort -V)
    if [ "${ORDER:0:4}" == "5.10" ] ; then
      JTAGCONF='-jtagconf -1,-1'
    fi
  fi
  if [ -e $JLINKPATH/libjlinkarm.so.6 ] ; then
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

"
	if [ $FILESIZE -le $((0x500000)) ]; then	# <= 5MB?
	  echo "# Program Kernel (5MB, Dual SPI flash)
  => sf probe 0:1 ; sf erase 100000 280000 ; sf write $ramaddr 100000 500000"
	elif [ $FILESIZE -le $((0x600000)) ]; then	# <= 6MB?
	  echo "# Program Kernel (6MB, Dual SPI flash)
  => sf probe 0:1 ; sf erase 100000 300000 ; sf write $ramaddr 100000 600000"
	fi
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
	elif [ $FILESIZE -le $((0xA00000))  ]; then	# <= 10MB?
	  echo "Program Rootfs (10MB)
  => sf probe 0:1 ; sf erase 00400000 500000 ; sf write $ramaddr 00400000 A00000"
	elif [ $FILESIZE -le $((0xC00000))  ]; then	# <= 12MB?
	  echo "Program Rootfs (12MB)
  => sf probe 0:1 ; sf erase 00400000 600000 ; sf write $ramaddr 00400000 C00000"
	elif [ $FILESIZE -le $((0xE00000))  ]; then	# <= 14MB?
	  echo "Program Rootfs (14MB)
  => sf probe 0:1 ; sf erase 00400000 700000 ; sf write $ramaddr 00400000 E00000"
	elif [ $FILESIZE -le $((0x1000000))  ]; then	# <= 16MB?
	  echo "Program Rootfs (16MB)
  => sf probe 0:1 ; sf erase 00400000 800000 ; sf write $ramaddr 00400000 1000000"
	elif [ $FILESIZE -le $((0x1200000))  ]; then	# <= 18MB?
	  echo "Program Rootfs (18MB)
  => sf probe 0:1 ; sf erase 00400000 900000 ; sf write $ramaddr 00400000 1200000"
	elif [ $FILESIZE -le $((0x1400000))  ]; then	# <= 20MB?
	  echo "Program Rootfs (20MB)
  => sf probe 0:1 ; sf erase 00400000 A00000 ; sf write $ramaddr 00400000 1400000"
	elif [ $FILESIZE -le $((0x1600000))  ]; then	# <= 22MB?
	  echo "Program Rootfs (22MB)
  => sf probe 0:1 ; sf erase 00400000 B00000 ; sf write $ramaddr 00400000 1600000"
	elif [ $FILESIZE -le $((0x1800000))  ]; then	# <= 24MB?
	  echo "Program Rootfs (24MB)
  => sf probe 0:1 ; sf erase 00400000 C00000 ; sf write $ramaddr 00400000 1800000"
	elif [ $FILESIZE -le $((0x1A00000))  ]; then	# <= 26MB?
	  echo "Program Rootfs (26MB)
  => sf probe 0:1 ; sf erase 00400000 D00000 ; sf write $ramaddr 00400000 1A00000"
	elif [ $FILESIZE -le $((0x1C00000))  ]; then	# <= 28MB?
	  echo "Program Rootfs (28MB)
  => sf probe 0:1 ; sf erase 00400000 E00000 ; sf write $ramaddr 00400000 1C00000"
	elif [ $FILESIZE -le $((0x1E00000))  ]; then	# <= 30MB?
	  echo "Program Rootfs (30MB)
  => sf probe 0:1 ; sf erase 00400000 F00000 ; sf write $ramaddr 00400000 1E00000"
	elif [ $FILESIZE -le $((0x2000000))  ]; then	# <= 32MB?
	  echo "Program Rootfs (24MB)
  => sf probe 0:1 ; sf erase 00400000 1000000 ; sf write $ramaddr 00400000 2000000"
	fi
  exit
  fi

fi

# Create output build directory
if [ ! -e $OUTDIR ] ; then
  mkdir -p $OUTDIR
fi

##### Check if we have all the host tools we need for menuconfig #####
if [ "$2" == "menuconfig" ] ; then
  CHECK=$(which ncurses5-config)
  if [ "$CHECK" == "" ] ; then
    banner_red "ncurses is not installed"
    echo -e "You need the package ncurses installed in order to use menuconfig."
    echo -e "In Ubuntu, you can install it by running:\n\tsudo apt-get install ncurses-dev\n"
    echo -e "Existing build script.\n"
    exit
  fi
fi

###############################################################################
# build kernel
###############################################################################
if [ "$1" == "kernel" ] || [ "$1" == "k" ] ; then
  banner_yellow "Building kernel"

  check_for_toolchain

  if [ "$2" == "" ] ; then
    echo " "
    echo "What do you want to build?"
    echo "For example:  (case sensitive)"
    echo " Traditional kernel:  ./build.sh kernel uImage"
    echo "         XIP kernel:  ./build.sh kernel xipImage"
    echo "  Kernel config GUI:  ./build.sh kernel menuconfig"
    exit
  fi

  if [ "$2" == "uImage" ] ; then
    CHECK=$(which mkimage)
    if [ "$CHECK" == "" ] ; then
      banner_red "mkimage is not installed"
      echo -e "You need the program mkimage installed in order to build a kernel uImage."
      echo -e "In Ubuntu, you can install it by running:\n\tsudo apt-get install u-boot-tools\n"
      echo -e "Existing build script.\n"
      exit
    fi
  fi

  cd $OUTDIR

  # extract linux-3.14
  if [ ! -e linux-3.14 ] ;then

    # Download linux-3.14
    if [ ! -e linux-3.14.tar.xz ] ;then
      wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.14.tar.xz
    fi

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
if [ "$1" == "u-boot" ] || [ "$1" == "u" ] ; then
  banner_yellow "Building u-boot"

  check_for_toolchain

  cd $OUTDIR

  # extract u-boot-2015.01
  if [ ! -e u-boot-2015.01 ] ;then

    # Download u-boot-2015.01.tar.bz2
    if [ ! -e u-boot-2015.01.tar.bz2 ] ;then
      wget ftp://ftp.denx.de/pub/u-boot/u-boot-2015.01.tar.bz2
    fi

    echo "extracting u-boot..."
    tar -xf u-boot-2015.01.tar.bz2
  fi

  cd u-boot-2015.01

  # Patch u-boot
  if [ ! -e include/configs/rskrza1.h ] ;then
    # Combine all the patches, then patch at once
    cat $ROOTDIR/patches-uboot/* > /tmp/uboot_patches.patch
    patch -p1 -i /tmp/uboot_patches.patch

  fi

  # Configure u-boot
  if [ ! -e .config ] ;then
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
if [ "$1" == "buildroot" ]  || [ "$1" == "b" ] ; then
  banner_yellow "Building buildroot"

  cd $OUTDIR

  if [ ! -e br_version.txt ] ; then
    echo "What version of Buildroot do you want to use?"
    echo "1. buildroot-2014.05"
    echo "2. buildroot-2016.08"
    echo -n "(select number)=> "
    read ANSWER
    if [ "$ANSWER" == "1" ] ; then
      echo "export BR_VERSION=2014.05" > br_version.txt
    elif [ "$ANSWER" == "2" ] ; then
      echo "export BR_VERSION=2016.08" > br_version.txt
    else
      echo "ERROR: \"$ANSWER\" is an invalid selection!"
      exit
    fi
    source br_version.txt
  fi

  # Download buildroot-$BR_VERSION.tar.bz2
  if [ ! -e buildroot-$BR_VERSION.tar.bz2 ] ;then
    wget http://buildroot.uclibc.org/downloads/buildroot-$BR_VERSION.tar.bz2
  fi

  # extract buildroot-$BR_VERSION
  if [ ! -e buildroot-$BR_VERSION/README ] ;then
    echo "extracting buildroot..."
    tar -xf buildroot-$BR_VERSION.tar.bz2
  fi

  cd buildroot-$BR_VERSION

  if [ ! -e output ] ; then
    mkdir -p output
  fi

  # Copy in our rootfs_overlay directory
  if [ ! -e output/rootfs_overlay ] ; then
    cp -a $ROOTDIR/patches-buildroot/rootfs_overlay output
  fi

 # Patch and Configure Buildroot for the RSKRZA1
  if [ ! -e configs/rskrza1_defconfig ]; then

    # Ask the user if they want to use the glib based Linaro toolchain
    # or build a uclib toolchain from scratch.
    banner_yellow "Toolchain selection"
    #echo -e "\n\n[ Toolchain selection ]"
    echo -e "What toolchain and C Library do you want to use for building applications?"
    echo ""
    echo "By default, we suggest the Linaro pre-built toolchain with hardware float"
    echo "support and glib C Libraries."
    echo ""
    echo "It is also possible to configure Buildroot to download and build from source"
    echo "a uClibc based toolchain. Note that while uClibc produces a smaller binary"
    echo "footprint, some open souce applications are not compatible."
    echo ""
    echo "Finaly, you may also configure Buildroot to use a toolchain that is already"
    echo "install on your machine."
    echo ""
    echo "What would you like to do?"
    echo "  1. Use the default Linaro toolchain (recommended)"
    echo "  2. Install Buildroot and then let me decide in the configuration menu (advanced)"
    echo -n "=> "
    for i in 1 2 3 ; do
      echo -n " Enter your choice (1 or 2): "
      read TC_CHOICE
      if [ "$TC_CHOICE" == "1" ] ; then break; fi
      if [ "$TC_CHOICE" == "2" ] ; then break; fi
      TRY=$i
    done

    if [ "$TRY" == "3" ] ; then
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
    cp -a $ROOTDIR/patches-buildroot/buildroot-$BR_VERSION/* configs/

    # Many times user don't care about audio, or LCD display.
    echo ""
    echo "======================================================================="
    echo ""
    echo "Are you going to use audio or video (LCD)?"
    echo "If you do not need audio or LCD, then we will not build those packages"
    echo "and that will make building faster."
    echo ""
    echo "What type of file system do you prefer?"
    echo ""
    echo "1 Audio and LCD (default)"
    echo "2 LCD only (no audio)"
    echo "3 Minimum system (no audio/video)"
    echo ""
    for i in 1 2 3 ; do
      echo -n " Enter your choice (1,2,3): "
      read ANSWER
      if [ "$ANSWER" == "1" ] ; then break; fi
      if [ "$ANSWER" == "2" ] ; then break; fi
      if [ "$ANSWER" == "3" ] ; then break; fi
      TRY=$i
    done
    if [ "$TRY" == "3" ] ; then
      echo -e "\nI give up! I have no idea what you want to do."
      exit
    fi

    if [ "$ANSWER" == "1" ] ; then
      # Select our full RSKRZA1 config
      make rskrza1_defconfig
    fi

    if [ "$ANSWER" == "2" ] ; then
      # Select our non-audio RSKRZA1 config
      make rskrza1_no_audio_defconfig
    fi

    if [ "$ANSWER" == "3" ] ; then
      # Select our non-audio RSKRZA1 config
      make rskrza1_min_defconfig
    fi

    if [ "$TC_CHOICE" == "2" ] ; then

      # User wants to select the toolchain themselves.
      make menuconfig
      
      echo ""
      echo "======================================================================="
      echo ""
      echo " If everything is how you like it, you can now build your system by running:"
      echo "     ./build.sh buildroot"
      echo ""
      echo " Or you can add additional SW packages by running:"
      echo "     ./build.sh buildroot menuconfig"
      echo ""

      exit

    fi
  fi

  # Trim buildroot temporary build files since they are not longer needed
  if [ "$2" == "trim" ] ;then

    echo "This will remove a good portion of intermediate build files under"
    echo "under the output/build directory since after they are build, they don't"
    echo "really serve much purpose anymore."
    echo ""
    echo -n "Continue? [y/N] "
    read ANS
    if [ "$ANS" != "y" ] || [ "$ANS" == "Y" ] ; then
      exit
    fi

    echo "First, we'll remove all the build files from output/build/host-* because once"
    echo "they are built and copied to output/host, there is not more use for them".
    echo "We only need to kee the .stamp_xxx files to tell Buildroot that they've already"
    echo "been built."
    echo -n "Press return to continue..."
    echo TRIMMING:
    TOTAL=`du -s -h -c $(ls -d output/build/host-*) | grep total`
    for HOST_DIR in $(ls -d output/build/host-*)
    do
      du -s -h $HOST_DIR
      find $HOST_DIR -type f ! -name '.stamp_*' -delete
      find $HOST_DIR -type l -delete
      rm -r -f `find $HOST_DIR -type d -name ".*"`
      find $HOST_DIR -type d -empty -delete
    done
    echo ""
    echo -n $TOTAL
    echo " deleted"

    echo ""
    echo "Next we will look at packages that you have already built and installed in your root"
    echo "file system. After the binaries have been copied to output/target and build libraries"
    echo "have been copied to output/staging, there is no more use for the files under output/build."
    echo ""
    echo "HINT: Just pressing enter defaults to 'y' "
    echo ""
    for BUILD_DIR in $(ls -d output/build/*)
    do
      #echo $BUILD_DIR
      #echo "${BUILD_DIR:13}"
      BUILD_DIR_NAME=${BUILD_DIR:13:18}

      # ignore the host- directories
      if [ "${BUILD_DIR_NAME:0:5}" == "host-" ] ; then
        continue
      fi

      # skip busybox because that is one that can be reconfigured
      # and reinstalled even after initial built
      if [ "${BUILD_DIR_NAME:0:7}" == "busybox" ] ; then
        continue
      fi

      # skip toolchain
      if [ "${BUILD_DIR_NAME:0:9}" == "toolchain" ] ; then
        continue
      fi

      # skip skeleton
      if [ "${BUILD_DIR_NAME:0:8}" == "skeleton" ] ; then
        continue
      fi

      # ignore directories without stamps
      if [ ! -e $BUILD_DIR/.stamp_target_installed ] ; then
        continue
      fi

      echo -n "Clean $BUILD_DIR_NAME ? [ Y/n ]: "
      read ANS
      if [ "$ANS" == "" ] || [ "$ANS" == "y" ] || [ "$ANS" == "Y" ] ; then

        du -s -h $BUILD_DIR
        find $BUILD_DIR -type f ! -name '.stamp_*' -delete
        find $BUILD_DIR -type l -delete
        rm -r -f `find $BUILD_DIR -type d -name ".*"`
        find $BUILD_DIR -type d -empty -delete
      fi
    done

    exit
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
  #   you were not root when you ran Buildroot) you can't boot and will just keep getting
  #   a "Permission denied" message after the file system is mounted"
  chmod a-s $BUILDROOT_DIR/output/target/bin/busybox

  #./mkfs.axfs -s -a $BUILDROOT_DIR/output/target rootfs.axfs.bin
  ./mkfs.axfs -s -a ../buildroot-$BR_VERSION/output/target rootfs.axfs.bin

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

