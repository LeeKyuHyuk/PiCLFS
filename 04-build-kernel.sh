#!/bin/bash
#
# PiCLFS kernel build script
# Optional parameteres below:
set -o nounset
set -o errexit

export LC_ALL=POSIX
export PARALLEL_JOBS=`cat /proc/cpuinfo | grep cores | wc -l`
export CONFIG_TARGET="aarch64-linux-gnu"
export CONFIG_HOST=`echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/'`
export CONFIG_LINUX_ARCH="arm64"
export CONFIG_LINUX_KERNEL_DEFCONFIG="bcm2711_defconfig"

export WORKSPACE_DIR=$PWD
export SOURCES_DIR=$WORKSPACE_DIR/sources
export OUTPUT_DIR=$WORKSPACE_DIR/out
export BUILD_DIR=$OUTPUT_DIR/build
export TOOLS_DIR=$OUTPUT_DIR/tools
export SYSROOT_DIR=$TOOLS_DIR/$CONFIG_TARGET/sysroot
export ROOTFS_DIR=$OUTPUT_DIR/rootfs
export KERNEL_DIR=$OUTPUT_DIR/kernel

export PATH="$TOOLS_DIR/bin:$TOOLS_DIR/sbin:$PATH"

# End of optional parameters

function step() {
  echo -e "\e[7m\e[1m>>> $1\e[0m"
}

function success() {
  echo -e "\e[1m\e[32m$1\e[0m"
}

function error() {
  echo -e "\e[1m\e[31m$1\e[0m"
}

function extract() {
  case $1 in
    *.tgz) tar -zxf $1 -C $2 ;;
    *.tar.gz) tar -zxf $1 -C $2 ;;
    *.tar.bz2) tar -jxf $1 -C $2 ;;
    *.tar.xz) tar -Jxf $1 -C $2 ;;
  esac
}

function check_environment {
  if ! [[ -d $SOURCES_DIR ]] ; then
    error "Please download tarball files!"
    error "Run './01-download-packages.sh'"
    exit 1
  fi
}

function check_tarballs {
    LIST_OF_TARBALLS="
      raspberrypi-kernel_1.20200212-1.tar.gz
    "

    for tarball in $LIST_OF_TARBALLS ; do
        if ! [[ -f $SOURCES_DIR/$tarball ]] ; then
            error "Can't find '$tarball'!"
            exit 1
        fi
    done
}

function timer {
  if [[ $# -eq 0 ]]; then
    echo $(date '+%s')
  else
    local stime=$1
    etime=$(date '+%s')
    if [[ -z "$stime" ]]; then stime=$etime; fi
    dt=$((etime - stime))
    ds=$((dt % 60))
    dm=$(((dt / 60) % 60))
    dh=$((dt / 3600))
    printf '%02d:%02d:%02d' $dh $dm $ds
  fi
}

check_environment
check_tarballs
total_build_time=$(timer)

rm -rf $BUILD_DIR $KERNEL_DIR
mkdir -pv $BUILD_DIR $KERNEL_DIR

step "[1/1] Raspberry Pi Linux 4.19.93"
extract $SOURCES_DIR/raspberrypi-kernel_1.20200212-1.tar.gz $BUILD_DIR
make -j$PARALLEL_JOBS ARCH=$CONFIG_LINUX_ARCH mrproper -C $BUILD_DIR/linux-raspberrypi-kernel_1.20200212-1
make -j$PARALLEL_JOBS ARCH=$CONFIG_LINUX_ARCH $CONFIG_LINUX_KERNEL_DEFCONFIG -C $BUILD_DIR/linux-raspberrypi-kernel_1.20200212-1
make -j$PARALLEL_JOBS ARCH=$CONFIG_LINUX_ARCH HOSTCC="gcc -O2 -I$TOOLS_DIR/include -L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" CROSS_COMPILE="$TOOLS_DIR/bin/$CONFIG_TARGET-" Image modules dtbs -C $BUILD_DIR/linux-raspberrypi-kernel_1.20200212-1
make -j$PARALLEL_JOBS ARCH=$CONFIG_LINUX_ARCH HOSTCC="gcc -O2 -I$TOOLS_DIR/include -L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" CROSS_COMPILE="$TOOLS_DIR/bin/$CONFIG_TARGET-" INSTALL_MOD_PATH=$ROOTFS_DIR modules_install -C $BUILD_DIR/linux-raspberrypi-kernel_1.20200212-1
mkdir -pv $KERNEL_DIR/overlays
cp -v $BUILD_DIR/linux-raspberrypi-kernel_1.20200212-1/arch/arm64/boot/Image $KERNEL_DIR
cp -v $BUILD_DIR/linux-raspberrypi-kernel_1.20200212-1/arch/arm64/boot/dts/broadcom/*.dtb $KERNEL_DIR
cp -v $BUILD_DIR/linux-raspberrypi-kernel_1.20200212-1/arch/arm/boot/dts/overlays/*.dtb* $KERNEL_DIR/overlays/
cp -v $BUILD_DIR/linux-raspberrypi-kernel_1.20200212-1/arch/arm/boot/dts/overlays/README $KERNEL_DIR/overlays/

rm -rf $BUILD_DIR/linux-raspberrypi-kernel_1.20200212-1

success "\nTotal kernel build time: $(timer $total_build_time)\n"
