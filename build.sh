#!/bin/bash

# Function: usage
function usage {
  echo -ne "\033[1;31m" # RED TEXT
  echo -e "\nWhat do you want to build?"
  echo -ne "\033[00m" # END TEXT COLOR
  echo -e "    ./build.sh config                  : Target Board Selection ($BOARD)"
  echo -e ""
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
  echo -e ""
  echo -e "    Current Target: $BOARD"
  echo -e ""
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

# Save current config settings to file
function save_config {
  echo "BOARD=$BOARD" > output/config.txt
  echo "CONSOLE=$CONSOLE" >> output/config.txt
  echo "DLRAM_ADDR=$DLRAM_ADDR" >> output/config.txt
  echo "UBOOT_ADDR=$UBOOT_ADDR" >> output/config.txt
  echo "DTB_ADDR=$DTB_ADDR" >> output/config.txt
  echo "KERNEL_ADDR=$KERNEL_ADDR" >> output/config.txt
  echo "ROOTFS_ADDR=$ROOTFS_ADDR" >> output/config.txt
  echo "QSPI=$QSPI" >> output/config.txt
}

###############################################################################
# script start
###############################################################################

# Save current directory
ROOTDIR=`pwd`

#Defaults (for RSK)
BOARD=rskrza1
CONSOLE=ttySC2
DLRAM_ADDR=0x08000000
UBOOT_ADDR=0x18000000
DTB_ADDR=0x180C0000
KERNEL_ADDR=0x18200000
ROOTFS_ADDR=0x18800000
QSPI=DUAL

# Create output build directory
if [ ! -e output ] ; then
  mkdir -p output
fi

# Create config.txt file, or read in current settings
if [ ! -e output/config.txt ] ; then
  save_config
else
  source output/config.txt
fi

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
# config
###############################################################################
if [ "$1" == "config" ] ; then

BRD_NAMES[0]=rskrza1 ; BRD_DESC[0]="RSK (RZ/A1H)"
    BRD_CON[0]=ttySC2
  BRD_DLRAM[0]=0x08000000
  BRD_UBOOT[0]=0x18000000
    BRD_DTB[0]=0x180C0000
 BRD_KERNEL[0]=0x18200000
 BRD_ROOTFS[0]=0x18800000
   BRD_QSPI[0]=DUAL

BRD_NAMES[1]=genmai ; BRD_DESC[1]="GENMAI (RZA1H)"
    BRD_CON[1]=ttySC2
  BRD_DLRAM[1]=0x08000000
  BRD_UBOOT[1]=0x18000000
    BRD_DTB[1]=0x180C0000
 BRD_KERNEL[1]=0x18200000
 BRD_ROOTFS[1]=0x18800000
   BRD_QSPI[1]=DUAL

BRD_NAMES[2]=streamit ; BRD_DESC[2]="Stream it! (RZ/A1LU)"
    BRD_CON[2]=ttySC3
  BRD_DLRAM[2]=0x0C000000
  BRD_UBOOT[2]=0x18000000
    BRD_DTB[2]=0x180C0000
 BRD_KERNEL[2]=0x18200000
 BRD_ROOTFS[2]=0x18800000
   BRD_QSPI[2]=SINGLE

BRD_NAMES[3]=grpeach ; BRD_DESC[3]="GR-PEACH (RZ/A1H)"
    BRD_CON[3]=ttySC2
  BRD_DLRAM[3]=0x20000000
  BRD_UBOOT[3]=0x18000000
    BRD_DTB[3]=0x180C0000
 BRD_KERNEL[3]=0x18100000
 BRD_ROOTFS[3]=0x18600000
   BRD_QSPI[3]=SINGLE

BRD_NAMES[4]=ylcdrza1h ; BRD_DESC[4]="YLCDRZA1H (RZ/A1H)"
    BRD_CON[4]=ttySC3
  BRD_DLRAM[4]=0x08000000
  BRD_UBOOT[4]=0x18000000
    BRD_DTB[4]=0x180C0000
 BRD_KERNEL[4]=0x18200000
 BRD_ROOTFS[4]=0x18800000
   BRD_QSPI[4]=DUAL

BRD_NAMES[5]=? ; BRD_DESC[5]="Custom Board"
    BRD_CON[5]=ttySC2
  BRD_DLRAM[5]=0x20000000
  BRD_UBOOT[5]=0x18000000
    BRD_DTB[5]=0x180C0000
 BRD_KERNEL[5]=0x18200000
 BRD_ROOTFS[5]=0x18800000
   BRD_QSPI[5]=SINGLE

BRD_CNT=$(echo ${#BRD_NAMES[@]})
BRD_CNT_MAX_INDEX=$(expr $BRD_CNT - 1)

  while [ "1" == "1" ]
  do

    CURRENT_DESC="custom"

    for i in `seq 0 $BRD_CNT_MAX_INDEX` ; do
      if [ "$BOARD" == "${BRD_NAMES[$i]}" ] ; then
        CURRENT_DESC="${BRD_DESC[$i]}"
        break
      fi
    done

    whiptail --title "Build Environment Setup"  --noitem --menu "Make changes the items below as needed.\nYou may use ESC+ESC to cancel." 0 0 0 \
	" Target Board: $BOARD [$CURRENT_DESC]" "" \
	"      console: /dev/$CONSOLE" "" \
	"     RAM addr: $DLRAM_ADDR" "" \
	"  u-boot addr: $UBOOT_ADDR" "" \
	"     DTB addr: $DTB_ADDR" "" \
	"  kernel addr: $KERNEL_ADDR" "" \
	"  rootfs addr: $ROOTFS_ADDR" "" \
	"         QSPI: $QSPI" "" \
	"Save" "" 2> /tmp/answer.txt

    #ans=$(head -c 3 /tmp/answer.txt)
    ans=$(cat /tmp/answer.txt)

    if [ "$ans" == "" ]; then
      break;
    fi

    if [ "$(grep "Target Board" /tmp/answer.txt)" != "" ] ; then

    whiptail --title "Build Environment Setup" --menu \
"Please select the platform you want to build for.\n"\
"If you have your own custom board, choose the last\n"\
"entry and enter the string name that you used for when\n"\
"creating your BSP.\n"\
"For example, if you enter \"rztoaster\", we will assume:\n"\
" * rztoaster_defconfig (for u-boot and kernel)\n"\
" * rztoaster_xip_defconfig (for XIP kernel)\n"\
" * r7s72100-rztoaster.dts (for Device Tree)\n"\
 0 0 40 \
	"1. ${BRD_NAMES[0]}" ":${BRD_DESC[0]}" \
	"2. ${BRD_NAMES[1]}" ":${BRD_DESC[1]}" \
	"3. ${BRD_NAMES[2]}" ":${BRD_DESC[2]}" \
	"4. ${BRD_NAMES[3]}" ":${BRD_DESC[3]}" \
	"5. ${BRD_NAMES[4]}" ":${BRD_DESC[4]}" \
	"6. ${BRD_NAMES[5]}" ": Define your own board..." \
 2> /tmp/answer.txt
    ans=$(cat /tmp/answer.txt)

    # No selection (cancel)
    if [ "$ans" == "" ] ; then
      continue
    fi

    CUR_INDEX=$(head -c 1 /tmp/answer.txt)
    CUR_INDEX=$(expr $CUR_INDEX - 1)

    if [ "$CUR_INDEX" == "5" ] ; then
      whiptail --title "Custom board name selection" --inputbox "Enter your board name:" 0 0 \
      2> /tmp/answer.txt
      # No selection (cancel)
      if [ "$ans" == "" ] ; then
        continue
      fi
      BRD_NAMES[5]=$(cat /tmp/answer.txt)

      whiptail --title "Custom board selected" --msgbox "In the main menu, please adjust settings as needed" 0 0
    fi

    BOARD=${BRD_NAMES[$CUR_INDEX]}
    CONSOLE=${BRD_CON[$CUR_INDEX]}
    DLRAM_ADDR=${BRD_DLRAM[$CUR_INDEX]}
    UBOOT_ADDR=${BRD_UBOOT[$CUR_INDEX]}
    DTB_ADDR=${BRD_DTB[$CUR_INDEX]}
    KERNEL_ADDR=${BRD_KERNEL[$CUR_INDEX]}
    ROOTFS_ADDR=${BRD_ROOTFS[$CUR_INDEX]}
    QSPI=${BRD_QSPI[$CUR_INDEX]}

    continue
  fi

  if [ "$(grep console /tmp/answer.txt)" != "" ] ; then
    whiptail --title "Serial Port Selection" --noitem --menu "What Serial port is your console on?" 0 0 40 \
	"ttySC0" "" \
	"ttySC1" "" \
	"ttySC2" "" \
	"ttySC3" "" \
	"ttySC4" "" \
	"ttySC5" "" \
	2> /tmp/answer.txt
      CONSOLE=$(cat /tmp/answer.txt)
  fi

  if [ "$(grep 'RAM addr' /tmp/answer.txt)" != "" ] ; then
    whiptail --title "Address selection" --inputbox \
"Enter the address of the RAM that you can download images to\n"\
"using J-Link.\n"\
"This is only needed for the './build.sh jlink' command.\n"\
"If you only have internal RAM (no SDRAM), then you would\n"\
"enter 0x20000000.\n"\
"If you have external SDRAM on CS2, then you would enter 0x08000000.\n"\
"If you have external SDRAM on CS3, then you would enter 0x0C000000.\n"\
 0 0 0x0C000000 \
    2> /tmp/answer.txt
    ans=$(cat /tmp/answer.txt)
    # No selection (cancel)
    if [ "$ans" == "" ] ; then
      continue
    fi
    DLRAM_ADDR=$ans
  fi

  if [ "$(grep 'u-boot addr' /tmp/answer.txt)" != "" ] ; then
    whiptail --title "Address selection" --inputbox "Enter the address of u-boot:" 0 0 0x18000000 \
    2> /tmp/answer.txt
    ans=$(cat /tmp/answer.txt)
    # No selection (cancel)
    if [ "$ans" == "" ] ; then
      continue
    fi
    UBOOT_ADDR=$(cat /tmp/answer.txt)
  fi

  if [ "$(grep 'DTB addr' /tmp/answer.txt)" != "" ] ; then
    whiptail --title "Address selection" --inputbox "Enter the address of the Device Tree Blob:" 0 0 0x180C0000 \
    2> /tmp/answer.txt
    ans=$(cat /tmp/answer.txt)
    # No selection (cancel)
    if [ "$ans" == "" ] ; then
      continue
    fi
    DTB_ADDR=$ans
  fi

  if [ "$(grep 'kernel addr' /tmp/answer.txt)" != "" ] ; then
    whiptail --title "Address selection" --inputbox "Enter the address of the Linux kernel:" 0 0 0x18200000 \
    2> /tmp/answer.txt
    ans=$(cat /tmp/answer.txt)
    # No selection (cancel)
    if [ "$ans" == "" ] ; then
      continue
    fi
    KERNEL_ADDR=$ans
  fi

  if [ "$(grep 'rootfs addr' /tmp/answer.txt)" != "" ] ; then
    whiptail --title "Address selection" --inputbox "Enter the address of the Root File System:" 0 0 0x18800000 \
    2> /tmp/answer.txt
    ans=$(cat /tmp/answer.txt)
    # No selection (cancel)
    if [ "$ans" == "" ] ; then
      continue
    fi
    ROOTFS_ADDR=$ans
  fi

  if [ "$(grep QSPI /tmp/answer.txt)" != "" ] ; then
    whiptail --title "QSPI Selection" --noitem --menu "Is your system single or dual QSPI?" 0 0 40 \
	"SINGLE" "" \
	"DUAL" "" \
	2> /tmp/answer.txt
    ans=$(cat /tmp/answer.txt)
    # No selection (cancel)
    if [ "$ans" == "" ] ; then
      continue
    fi
    QSPI=$ans
  fi

  if [ "$(grep "Save" /tmp/answer.txt)" != "" ] ; then
    save_config
    break;
  fi

  done

  exit
fi

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
ADDRESS: (Optional) Default is $DLRAM_ADDR (beginning of your RAM)

Examples:

  #---------------------------------------------------------------------
  # These examples download the images to RAM, then you would use u-boot
  # to program the images from RAM to QSPI flash
  #---------------------------------------------------------------------

  # u-boot
  ./build.sh jlink output/u-boot-2015.01/u-boot.bin

  # Device Tree Blob
  ./build.sh jlink output/linux-3.14/arch/arm/boot/dts/r7s72100-$BOARD.dtb

  # Kernel
  ./build.sh jlink output/linux-3.14/arch/arm/boot/uImage
  ./build.sh jlink output/linux-3.14/arch/arm/boot/xipImage

  # Root File System
  ./build.sh jlink output/buildroot-$BR_VERSION/output/images/rootfs.squashfs
  ./build.sh jlink output/axfs/rootfs.axfs.bin

  #---------------------------------------------------------------------
  # These examples program the image directly into QSPI using the J-LINK
  # NOTE that the J-Link can only directly program a SINGLE SPI flash
  #---------------------------------------------------------------------

  ./build.sh jlink output/u-boot-2015.01/u-boot.bin 0x18000000

  ./build.sh jlink output/linux-3.14/arch/arm/boot/dts/r7s72100-$BOARD.dtb $DTB_ADDR
"
  if [ "$QSPI" == "SINGLE" ] ; then
   echo \
"  ./build.sh jlink output/linux-3.14/arch/arm/boot/uImage $KERNEL_ADDR
  ./build.sh jlink output/linux-3.14/arch/arm/boot/xipImage $KERNEL_ADDR

  ./build.sh jlink output/buildroot-$BR_VERSION/output/images/rootfs.squashfs $ROOTFS_ADDR
  ./build.sh jlink output/axfs/rootfs.axfs.bin $ROOTFS_ADDR
"
  fi
    echo -ne "\033[1;31m" # RED TEXT
    echo -ne "\nNOTE:"
    echo -ne "\033[00m" # END TEXT COLOR
    echo -e "Your board should be up and running in u-boot first\n     (ie, not Linux) before executing this command."

    exit
 fi

  # Shortcuts for common images to program
  # change our passed arguments to full paths
  if [ "$2" == "uboot" ] || [ "$2" == "u-boot" ] ; then
    set -- $1 output/u-boot-2015.01/u-boot.bin 0x18000000
  fi
  if [ "$2" == "dtb" ] ; then
    set -- $1 output/linux-3.14/arch/arm/boot/dts/r7s72100-$BOARD.dtb $DTB_ADDR
  fi
  if [ "$2" == "uImage" ] || [ "$2" == "ku" ]; then
    set -- $1 output/linux-3.14/arch/arm/boot/uImage $3
  fi
  if [ "$2" == "xipImage" ] || [ "$2" == "kx" ] ; then
    set -- $1 output/linux-3.14/arch/arm/boot/xipImage $3
  fi
  if [ "$2" == "rootfs_axfs" ] || [ "$2" == "ra" ] ; then
    set -- $1 output/axfs/rootfs.axfs.bin $3
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
    ramaddr=$DLRAM_ADDR
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

  if [ ${ramaddr:0:4} == "0x18" ] ; then
    exit
  fi

  SF_PROBE=""
  if [ "$QSPI" == "DUAL" ] ; then
    SF_PROBE=":1"
  fi

  ############ u-boot Programming ############
  CHECK=$(echo $dlfile | grep u-boot)
  if [ "$CHECK" != "" ] ; then
  echo "Example program operations:

# Rewrite u-boot (512 KB):
=> sf probe 0 ; sf erase 0 80000 ; sf write $ramaddr 0 80000
"
  exit
  fi

  ############ DTB Programming ############
  CHECK=$(echo $dlfile | grep dtb)
  if [ "$CHECK" != "" ] ; then
    SPI_ADDR=$(printf "%x\n" $(($DTB_ADDR-0x18000000)))
    echo "Example program operations:

# Program DTB (32 KB)
=> sf probe 0 ; sf erase $SPI_ADDR 40000 ; sf write $ramaddr $SPI_ADDR 8000
"
  exit
  fi
  ############ Kernel Programming ############
  CHECK=$(echo $dlfile | grep Image)
  if [ "$CHECK" != "" ] ; then
    # Determine SPI flash offset
    SPI_ADDR=$(printf "%x\n" $(($KERNEL_ADDR-0x18000000)))

    # Calculate how much you need to program (round up to next 1MB)
    SPI_SZ_P=$(printf "%d\n" $(($FILESIZE/0x100000 + 1)))
    SPI_SZ_MB=$(printf "%d\n" $(($SPI_SZ_P)))
    SPI_SZ_P=$(printf "%x\n" $(($SPI_SZ_P*0x100000)))

    echo -e "Example program operations:\n"

    # Make adjustments for Dual SPI flash
    if [ "$QSPI" == "DUAL" ] ; then
      SPI_ADDR=$(printf "%x\n" $((0x$SPI_ADDR/2))) # SPI address is half
      SPI_SZ_E=$(printf "%x\n" $((0x$SPI_SZ_P/2))) # Erase size is half of program size
    else
      SPI_SZ_E=$SPI_SZ_P
    fi

        echo "# Program Kernel (${SPI_SZ_MB}MB, $QSPI SPI flash)
  => sf probe 0$SF_PROBE ; sf erase $SPI_ADDR $SPI_SZ_E ; sf write $ramaddr $SPI_ADDR $SPI_SZ_P"

    exit
  fi

  ############ Rootfs Programming ############
  CHECK=$(echo $dlfile | grep rootfs)
  if [ "$CHECK" != "" ] ; then
    # Determine SPI flash offset
    SPI_ADDR=$(printf "%x\n" $(($ROOTFS_ADDR-0x18000000)))

    # Calculate how much you need to program (round up to next 1MB)
    SPI_SZ_P=$(printf "%d\n" $(($FILESIZE/0x100000 + 1)))
    SPI_SZ_MB=$(printf "%d\n" $(($SPI_SZ_P)))
    SPI_SZ_P=$(printf "%x\n" $(($SPI_SZ_P*0x100000)))
    echo -e "Example program operations:\n"

    # Make adjustments for Dual SPI flash
    if [ "$QSPI" == "DUAL" ] ; then
      SPI_ADDR=$(printf "%x\n" $((0x$SPI_ADDR/2))) # SPI address is half
      SPI_SZ_E=$(printf "%x\n" $((0x$SPI_SZ_P/2))) # Erase size is half of program size
    else
      SPI_SZ_E=$SPI_SZ_P
    fi

        echo "# Program Rootfs (${SPI_SZ_MB}MB, $QSPI SPI flash)
  => sf probe 0$SF_PROBE ; sf erase $SPI_ADDR $SPI_SZ_E ; sf write $ramaddr $SPI_ADDR $SPI_SZ_P"

    if [ "$BOARD" == "rskrza1" ] && [ $FILESIZE -ge $((0x2000000)) ] ; then	# >= 32MB?
      echo "Are you sure you have enough SDRAM space? The RSK only has 32MB of SDRAM."
    fi
    echo -e "\n"
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

  # install linux-3.14
  if [ ! -e linux-3.14 ] ;then

    # Download linux-3.14
    #if [ ! -e linux-3.14.tar.xz ] ;then
    #  wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.14.tar.xz
    #fi
    #echo "extracting kernel..."
    #tar -xf linux-3.14.tar.xz

    CHECK=`which git`
    if [ "CHECK" == "" ] ; then
      banner_red "git is not installed"
      echo -e "You need git in order to download the kernel"
      echo -e "In Ubuntu, you can install it by running:\n\tsudo apt-get install git\n"
      echo -e "Existing build script.\n"
      exit
    fi

    # clone from repository (stable release)
    # commit f5fa66116224d50285df5a8c11c8faa3d6199f01
    #        (rskrza1: add direct register mapping for SWRSTCR1)
    KERNEL_COMMIT='f5fa661162'
    git clone -n https://github.com/renesas-rz/linux-3.14.git
    cd linux-3.14
    git checkout $KERNEL_COMMIT
    cd ..

      #manual download:
      #wget https://github.com/renesas-rz/linux-3.14/archive/$KERNEL_COMMIT.zip
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
  XIPCHECK=`grep -s CONFIG_XIP_KERNEL=y .config`
  if [ "$2" == "uImage" ] ;then
    IMG_BUILD=1
    if [ ! -e .config ] || [ "$XIPCHECK" != "" ]; then
      # Need to configure kernel first
      make ${BOARD}_defconfig
    fi
    # re-configure kernel if we changed target board
    CHECK=$(grep -i CONFIG_MACH_${BOARD}=y .config )
    if [ "$CHECK" == "" ] ; then
      echo "Reconfiguring for new board..."
      make ${BOARD}_defconfig
    fi
  fi
  if [ "$2" == "xipImage" ] ;then
    IMG_BUILD=1
    if [ ! -e .config ] || [ "$XIPCHECK" == "" ]; then
      # Need to configure kernel first
      make ${BOARD}_xip_defconfig
    fi
    # re-configure kernel if we changed target board
    CHECK=$(grep -i CONFIG_MACH_${BOARD}=y .config )
    if [ "$CHECK" == "" ] ; then
      echo "Reconfiguring for new board..."
      make ${BOARD}_xip_defconfig
    fi
  fi

  if [ "$IMG_BUILD" == "1" ] ; then
    # NOTE: Adding "LOCALVERSION=" to the command line will get rid of the
    #       plus sign (+) at the end of the kernel version string. Alternatively,
    #       we could have created a empty ".scmversion" file in the root.
    # NOTE: We have to make the Device Tree Blobs too, so we'll add 'dtbs' to
    #       the command line
    echo -e "make LOCALVERSION= -j$BUILD_THREADS $2 dtbs\n"
    make LOCALVERSION= -j$BUILD_THREADS $2 dtbs

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

  # install u-boot-2015.01
  if [ ! -e u-boot-2015.01 ] ; then

    # Download u-boot-2015.01.tar.bz2
    #if [ ! -e u-boot-2015.01.tar.bz2 ] ;then
    #  wget ftp://ftp.denx.de/pub/u-boot/u-boot-2015.01.tar.bz2
    #fi
    #echo "extracting u-boot..."
    #tar -xf u-boot-2015.01.tar.bz2

    CHECK=`which git`
    if [ "CHECK" == "" ] ; then
      banner_red "git is not installed"
      echo -e "You need git in order to download the kernel"
      echo -e "In Ubuntu, you can install it by running:\n\tsudo apt-get install git\n"
      echo -e "Existing build script.\n"
      exit
    fi

    # clone from repository (stable release)
    # commit 58027428ffaebbbee4a61b2ae81d3f1f3549bfd1
    #        (grpeach: support ethernet)
    UBOOT_COMMIT='58027428ff'
    git clone -n https://github.com/renesas-rz/u-boot-2015.01.git
    cd u-boot-2015.01
    git checkout $UBOOT_COMMIT
    cd ..

      #manual download:
      #wget https://github.com/renesas-rz/u-boot-2015.01/archive/$KERNEL_COMMIT.zip

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
    make ${BOARD}_config
  fi

  # re-configure u-boot if we changed target board
  CHECK=$(grep CONFIG_SYS_BOARD .config | grep $BOARD)
  if [ "$CHECK" == "" ] ; then
    echo "Reconfiguring for new board..."
    make ${BOARD}_config
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

    # Apply Buildroot patches
    for i in $ROOTDIR/patches-buildroot/buildroot-$BR_VERSION/*.patch; do patch -p1 < $i; done

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

  # Switch out the console
  CHECK=`grep BR2_TARGET_GENERIC_GETTY_PORT=\"$CONSOLE\" $BUILDROOT_DIR/.config`
  if [ "$CHECK" == "" ] ; then
    sed -i 's/ttySC./'"$CONSOLE"'/g' $BUILDROOT_DIR/.config
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
    CHECK=$(uname -m)
    if [ "$CHECK" == "x86_64" ] ; then
      # 64-bit OS
      cp -a ../../axfs/mkfs.axfs-legacy/mkfs.axfs.64 mkfs.axfs
    else
      # 32-bit OS
      cp -a ../../axfs/mkfs.axfs-legacy/mkfs.axfs.32 mkfs.axfs
    fi

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

###############################################################################
# update
###############################################################################
if [ "$1" == "update" ] ; then
  banner_yellow "repository update"

  if [ "$2" == "" ] ; then
    echo -e "Update:"
    echo -e "This command will 'git pull' the latest code from the github repositories."
    echo -e "Any changes you have made will be save and re-applied after the updated."
    echo -e "Basically, we will do the following:"
    echo -e "  git stash      # save current changes"
    echo -e "  git pull       # download latest version"
    echo -e "  git stash pop  # re-apply saved changes"
    echo -e ""
    echo -e "  ./build.sh update b   # updates bsp build scripts"
    echo -e "  ./build.sh update u   # updates uboot source"
    echo -e "  ./build.sh update k   # updates kernel source "
    echo -e ""
    exit
  fi

  if [ "$2" == "b" ] ; then
    git stash
    git pull
    git stash pop
    exit
  fi

  if [ "$2" == "k" ] ; then
    if [ ! -e output/linux-3.14 ] ; then
      cd output
      git clone https://github.com/renesas-rz/linux-3.14.git
    else
      cd output/linux-3.14
      git stash
      git checkout master    # Needed if using bsp v.1.3.0
      git pull
      git stash pop
    fi
    exit
  fi

  if [ "$2" == "u" ] ; then
    if [ ! -e output/u-boot-2015.01 ] ; then
      cd output
      git clone https://github.com/renesas-rz/u-boot-2015.01.git
    else
      cd output/u-boot-2015.01
      git stash
      git checkout 2015.01-rskrza1   # Needed if using bsp v.1.3.0
      git pull
      git stash pop
    fi
    exit
  fi
fi

