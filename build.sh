#!/bin/bash

set -e

export CROSS_COMPILE="/usr/local/arm-2009q3/bin/arm-none-eabi-"
export KBUILD_BUILD_VERSION="tdm1.0beta2"
#export LOCALVERSION="-G1XXKPN-CL562447"

which ccache >/dev/null 2>&1
if [ $? -eq 0 ]; then
	export CROSS_COMPILE="ccache $CROSS_COMPILE"
fi

cpus=$(grep "^processor" /proc/cpuinfo | wc -l)

usage()
{
	echo "Usage: build.sh <model> <project>"
	echo "Usage: build.sh clean"
	echo "  eg. build.sh ypg1 cm7"
	exit 1
}

opt_clean=""
if [ "$1" = "clean" ]; then
	make clean
	exit 0
fi

if [ "$#" -ne 2 ]; then
	usage
fi

model="$1"
project="$2"

if [ ! -f "arch/arm/configs/tdm_${model}_defconfig" ]; then
	echo "Cannot find config"
	exit 1
fi
if [ ! -d "../initramfs-${project}" ]; then
	echo "Cannot find initramfs"
	exit 1
fi

if [ ! -f ".config" -o "$model" != "$lastmodel" ]; then
	make tdm_${model}_defconfig
fi

initramfs_source=$(grep "^CONFIG_INITRAMFS_SOURCE" .config | \
	cut -d'=' -f2 | sed 's/"//g')
if [ -z "$initramfs_source" ]; then
	echo "Cannot find initramfs dir in config"
	exit 1
fi

rm -f usr/initramfs_data.cpio

# XXX: check whether file or dir
initramfs_dir=$(dirname $initramfs_source)

rm -rf "$initramfs_dir"
mkdir -p "$initramfs_dir"
if [ -d "initramfs/common" ]; then
	cp -a initramfs/common/* "$initramfs_source"
fi
cp -a initramfs/${project}/* "$initramfs_dir"

make -j${cpus}
cp arch/arm/boot/zImage kernel-${model}-${project}.bin
md5sum kernel-${model}-${project}.bin
