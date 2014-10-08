#!/bin/bash

CHECK=$(which arm-linux-gnueabihf-gcc)
if [ "$CHECK" == "" ] ; then
  source /home/renesas/rza1/setup_env.sh
  echo -e " ERROR!
Compiler not found in path. Please set up environment first.
Example:
   export PATH=${PATH_TO_COMPILER}/bin:$PATH
"
  exit
fi

CROSS_COMPILE="arm-linux-gnueabihf-"
ARCH=arm
TOOLCHAIN=arm-linux-gnueabihf

if [ "$1" == "clean" ] ;then
  cd librzjpeg
  #make clean
  make distclean
  #make maintainer-clean
  exit
fi


# choose fallback SW JPEG library
JPGLIB=jpeg-8d
#JPGLIB=libjpeg-turbo-1.3.1	# not tested yet

if [ "$JPGLIB" == "jpeg-8d" ]; then
echo "#############################################"
echo "#    jpeg-8d"
echo "#############################################"

# Download
if [ ! -e jpegsrc.v8d.tar.gz ]; then
  wget http://www.ijg.org/files/jpegsrc.v8d.tar.gz
fi

# Extract and Configure and make
if [ ! -e jpeg-8d ]; then
  tar -xzf jpegsrc.v8d.tar.gz
  cd jpeg-8d

  PREFIX=`pwd`/_install
  ./configure --host=$TOOLCHAIN --prefix="$PREFIX"
  make
  make install
  cd ..
  # Output files will now be in  jpeg-8d/_install

  if [ ! -e jpeg-8d/_install/lib/libjpeg.so ] ; then
    echo -e "\n\nBuild Failed!\n\n"
    exit
  fi

  # LIBJPEG_REMOVE_USELESS_TOOLS
  #rm -f $(addprefix $(TARGET_DIR)/usr/bin/,cjpeg djpeg jpegtrans rdjpgcom wrjpgcom)
fi
fi


if [ "$JPGLIB" == "libjpeg-turbo-1.3.1" ]; then
echo "#############################################"
echo "#    libjpeg-turbo"
echo "#############################################"

# Download
if [ ! -e libjpeg-turbo-1.3.1.tar.gz ]; then
  wget http://iweb.dl.sourceforge.net/project/libjpeg-turbo/1.3.1/libjpeg-turbo-1.3.1.tar.gz
fi

# Extract and Configure and make
if [ ! -e libjpeg-turbo-1.3.1 ]; then
  tar -xzf libjpeg-turbo-1.3.1.tar.gz
  cd libjpeg-turbo-1.3.1

  PREFIX=`pwd`/_install
  ./configure --host=$TOOLCHAIN --prefix="$PREFIX" --with-simd
  make
  make install
  cd ..

  # Output files will now be in  libjpeg-turbo-1.3.1/_install
  if [ ! -e libjpeg-turbo-1.3.1/_install/lib/libturbojpeg.so ] ; then
    echo -e "\n\nBuild Failed!\n\n"
    exit
  fi

  # remove Useless tools
  #rm -f _install/bin cjpeg djpeg jpegtrans rdjpgcom tjbench wrjpgcom

fi
fi


################################## save path ##################################
# Save the location of jpeg library files
export JPEGPATH=`pwd`/$JPGLIB/_install


echo "#############################################"
echo "#    librzjpeg"
echo "#############################################"
cd librzjpeg
 # copy in our jpeg-8d files to 'libjpegfile'  (as specified in configure.ac)
 #cp ../libjpeg-8d/_install/include/*.h libjpegfile
 #cp ../libjpeg-8d/_install/lib/*.a libjpegfile

if [ ! -e Makefile ] ; then
  autoreconf -vif
  PREFIX=`pwd`/_install

  if [ "$1" == "debug" ] ; then
    ADD_DEBUG=-DSHJPEG_DEBUG
  fi
  ./configure --host=$TOOLCHAIN --prefix="$PREFIX" CPPFLAGS="-I$JPEGPATH/include $ADD_DEBUG" LDFLAGS="-L$JPEGPATH/lib"
fi

make

cd ..

echo "#############################################"
echo "#    Building output directory"
echo "#############################################"
mkdir -p output/lib
cp -v $JPGLIB/_install/lib/libjpeg.so* output/lib
mkdir -p output/bin
cp -v librzjpeg/tests/.libs/rzjpegtest output/bin
cp -v librzjpeg/src/.libs/librzjpeg.so* output/lib
mkdir -p output/etc
cp -av etc output


echo "#############################################"
echo "#    Everything you need is now in \"output\""
echo "#############################################"


