Hello World Application Example


This example shows you can build your own applications and add them to
the file system.


Step 1. Set up your build environment

 * Start in the base directory of the BSP (where build.sh is located).

 * Enter the command below to set the build environment.

	$ export ROOTDIR=$(pwd) ; source ./setup_env.sh

  NOTE: You can also type "./build.sh env" which will print out that
  command that you can copy/paste into the terminal.

Step 2. Build your application and add it to your file system.

 * The first step defined and environment variable BUILDROOT_DIR
   that the Makefile in this directory can use to then figure out
   where the toolchain is and where the sysroot (shared libraries)
   are.
   Enter the following commands:

	$ cd hello_world
	$ make
	$ make install
	$ cd ..
	$ ./build.sh buildroot
	$ ./build.sh axfs


Step 3. Program the new file system into your board.

	NOTE: This requires the Segger J-Link drivers and software to be
	installed on your Linux machine. Please see doc/User_Guild.html for
	more information on how to install them.

 * Make sure you boards is powered up and J-Link is plugged in

 * Make sure your board is sitting at the u-boot prompt

 * Enter the following command:
	$ ./build.sh jlink

   This will give you some information and some possible example you might want
   to chose.
   For example, if you are using a SquashFS image, then you would enter this on
   the command line:

	./build.sh jlink output/buildroot-2014.05/output/images/rootfs.squashfs

   However, if you are using a AXFS file system, you would enter this on the
   command line:

	./build.sh jlink output/axfs/rootfs.axfs.bin

   At this point, the JLink will download your binary to SDRAM on the
   RSK board.

 * After the download has completed, the script should have printed out a
   set of u-boot commands that you should copy/paste into your u-boot prompt
   on your board. What is printed changed based if you downloaded a kernel image,
   or u-boot image, or rootfs image. In this case, you should probably see
   something like this:


	Script processing completed.

	-----------------------------------------------------
	                File size was:
                	2.9M      /tmp/rootfs.squashfs.bin
	-----------------------------------------------------
	Example program operations:

	Program Rootfs (4MB)
	  => sf probe 0:1 ; sf erase 00400000 200000 ; sf write 0x08000000 00400000 400000


   At this point, you want to copy that u-boot command line and paste it into
   your serial terminal. That will program the binary that you download to RAM
   into Flash.
   Now when you boot your board, you should find your 'hello' executable
   under /root/bin

Step 4. Download your application over the serial console

	This is an alternative to re-flashing your SPI flash each time you
	rebuild your application.

	Even though file systems such as squashfs and axfs are read-only,
	the /tmp directory on your target board will be RAM based, so
	you can write files to it.

	This section explains how you can send down a file using ZMODEM from
	your host PC to your board using the current serial console connection.

	* You will first need to add the package 'lrzsz' to both your host PC
	  and target board file system.

	(host)$ sudo apt-get install lrzsz

	(rza1 bsp)$ ./build.sh buildroot menuconfig

		Target packages  --->
			Networking applications  --->
				[*] lrzsz

		Then rebuild your rootfs (./build.sh buildroot) and download
		this new filesystem to your board (./build.sh jlink)

	* Send a file from host to board. First, in the serial console terminal,
	  change into a writeable directory such as /tmp. If you have something
	  like an SD Card or USB stick mounted, you could use that a well. After
	  you enter teh 'rz' command, your serial console will be unusable until
	  the transfer is complete.

		(rza1)$ cd /tmp
		(rza1)$ rz -y

	* Then on the host side, send the binary application file down.

	[ Linux ]
		* Open a terminal window other than what your console is in (since
		it will become unusable after the "rz" command is executed).

		* You can use the application minicom to do this:
		$ minicom -D /dev/ttyACM0 -b 115200

		* !!NOTE!! By default, the "/dev/ttyACM0" device will be owned by "root"
		  and part of the group "dialout".
			(host)$ ls -l /dev/ttyACM0
			crw-rw---- 1 root dialout 166, 0 Mar 16 14:24 /dev/ttyACM0
		  Therefore, if you try to connect with minicom and you get a "permission denied",
		  error because your user account is not part of the dialout group.
		  Use the following command to add yourself to the dialout group:

			(host)$ sudo usermod -a -G dialout $(id -un)
			NOW, YOU MUST EITHER REBOOT or LOG OUT AND LOG BACK IN


		* Change into the directory of your 'hello' application

			(host)$ cd rskrza1_bsp/hello_world

		* Send the file using ZMODEM directly to the RZ/A1 RSK serial
		  driver (/dev/ttyACM0)

			(host)$ sz -b hello > /dev/ttyACM0 < /dev/ttyACM0

	[ Windows TeraTerm ]
		If you are using TeraTerm in Windows for your serial console
		communications, TeraTerm has ZMODEM functionality built in.

			File >> Transfer >> ZMODEM >> Send...

		NOTE: When using TeraTerm, you will have to change the file
		permissions to add executable again after download (chmod +x hello)


	* Receiving Files
	If you want to send a file from your board to the PC, you only need to
	enter the following command if you are using minicom on your Linux PC:

		(rza1)$ sz -b file-to-send

	The file will automatically be sent to the PC and show up in your user home
	direcotry ( ~/ ).
			(host)$ ls -l ~/file-to-send

	Note that if you do not remove that file from your home directory and you
	send another file with the same name, minicom will not overwrite the file,
	but instead append a .0 on the end of the filename.

