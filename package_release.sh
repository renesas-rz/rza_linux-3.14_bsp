#!/bin/bash

NAME=RSKRZA1-BSP-V1.3.0
TMP=/tmp/$NAME

CUR_DIR=$(pwd)

echo "Deleting previous versions..."
if [ -e $TMP ] ; then
  rm -rf $TMP
fi
if [ -e $NAME.tar ] ; then
  rm $NAME.tar
fi
if [ -e $NAME.tar.bz2 ] ; then
  rm $NAME.tar.bz2
fi
if [ -e $NAME.tar.xz ] ; then
  rm $NAME.tar.xz
fi

echo "Removing execute attributes left over for Windows testing..."
chmod -x Extra/J-Link_QSPI_Program/*
chmod +x Extra/J-Link_QSPI_Program/*.sh

echo "Making staging directory..."
mkdir -p $TMP

echo "Copying directories..."
cp -a axfs $TMP
cp -a doc $TMP
cp -a Extra $TMP
cp -a hello_world $TMP
cp -a mem $TMP
cp -a patches-buildroot $TMP
cp -a patches-kernel $TMP
cp -a patches-uboot $TMP

echo "Copying files..."
cp -a build.sh $TMP
cp -a release_note_E.txt $TMP
cp -a setup_env.sh $TMP

echo "TAR-ing $NAME..."
cd $TMP
cd ..
tar -cf $NAME.tar $NAME

echo "Moving TAR back to local directory..."
mv $NAME.tar $CUR_DIR
cd $CUR_DIR

echo "Making BZ2..."
bzip2 -kv $NAME.tar

echo "Making XZ..."
xz -kv $NAME.tar

