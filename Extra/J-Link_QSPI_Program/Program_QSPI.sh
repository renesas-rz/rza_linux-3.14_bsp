#!/bin/bash

CHECK=`which JLinkExe`
if [ "$CHECK" == "" ] ;then
  echo "Segger J-Link for Linux not installed."
  echo "Please visit https://www.segger.com/jlink-software.html"
  exit
fi

echo ""
echo "------------------------------------------------------------------------"
echo ""

echo "OPTIONS"
echo "1 = Program u-boot"
echo "2 = Program Device Tree Blob"
echo "3 = Program Kernel (uImage)"
echo "4 = Program Kernel (xipImage)"
echo "5 = Program Rootfs (squashfs)"
echo "6 = Program Rootfs (axfs)"
echo "9 = Exit"
echo -n "Choose option: "
read REPLY
if [ "$REPLY" == "1" ];then REPLY_OK=1; fi
if [ "$REPLY" == "2" ];then REPLY_OK=1; fi
if [ "$REPLY" == "3" ];then REPLY_OK=1; fi
if [ "$REPLY" == "4" ];then REPLY_OK=1; fi
if [ "$REPLY" == "5" ];then REPLY_OK=1; fi
if [ "$REPLY" == "6" ];then REPLY_OK=1; fi
if [ "$REPLY" == "9" ];then exit; fi
if [ "$REPLY_OK" != "1" ]; then
  echo "ERROR: Please select from the list only."
  exit
fi

echo "

Remove power (5V) to the board before continuing. 
Set SW6 as instructed below:
SW6-1 OFF, SW6-2 ON, SW6-3 OFF, SW6-4 ON, SW6-5 ON, SW6-6 ON

      ON
    +-------------+
    |   -   - - - |
    | -   -       |
    +-------------+
      1 2 3 4 5 6 

Reconnect power (5V) to the board before continuing. 
"
echo "Press enter to continue"
read dummy

echo "------------------------------------------------------------------------"

# =====u-boot========
if [ "$REPLY" == "1" ]; then
  JLinkExe -speed 12000 -if JTAG -device R7S721001 -CommanderScript load_spi_uboot.txt
fi

# =====Device Tree Blob========
if [ "$REPLY" == "2" ]; then
  JLinkExe -speed 12000 -if JTAG -device R7S721001 -CommanderScript load_spi_dtb.txt
fi

# =====Kernel (uImage)========
if [ "$REPLY" == "3" ]; then
  JLinkExe -speed 12000 -if JTAG -device R7S721001_DualSPI -CommanderScript load_spi_kernel_uImage.txt
fi

# =====Kernel (xipImage)========
if [ "$REPLY" == "4" ]; then
  JLinkExe -speed 12000 -if JTAG -device R7S721001_DualSPI -CommanderScript load_spi_kernel_xipImage.txt
fi

# =====Rootfs (squashfs)========
if [ "$REPLY" == "5" ]; then
  JLinkExe -speed 12000 -if JTAG -device R7S721001_DualSPI -CommanderScript load_spi_rootfs_squashfs.txt
fi

# =====Rootfs (axfs)========
if [ "$REPLY" == "6" ]; then
  JLinkExe -speed 12000 -if JTAG -device R7S721001_DualSPI -CommanderScript load_spi_rootfs_axfs.txt
fi

echo "------------------------------------------------------------------------"

echo "Press enter to continue"
read dummy
echo "

 NOTE:
       When you are done programming, have to remove power from the board for 5 seconds
       in order to be able to boot from QSPI again.


"

echo "Press enter to continue"
read dummy
echo "done"

