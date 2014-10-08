#!/bin/bash

NAME=RSKRZA1-BSP-V1.0
TMP=/tmp/$NAME

CUR_DIR=$(pwd)

# Delete previous versions
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


# Make staging directory
mkdir -p $TMP

cp -a doc $TMP
cp -a Extra $TMP
cp -a librzjpeg $TMP
cp -a patches-buildroot $TMP
cp -a patches-kernel $TMP
cp -a patches-uboot $TMP

cp -a build.sh $TMP
cp -a release_note_E.txt $TMP
cp -a setup_env.sh $TMP

cd $TMP
cd ..
tar -cf $NAME.tar $NAME
mv $NAME.tar $CUR_DIR

cd $CUR_DIR
bzip2 -k $NAME.tar
xz -k $NAME.tar

