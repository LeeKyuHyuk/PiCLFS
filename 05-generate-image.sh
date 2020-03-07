#!/bin/bash
#
# PiCLFS image generate script
# Optional parameteres below:
set -o nounset
set -o errexit

export WORKSPACE_DIR=$PWD
export SOURCES_DIR=$WORKSPACE_DIR/sources
export OUTPUT_DIR=$WORKSPACE_DIR/out
export BUILD_DIR=$OUTPUT_DIR/build
export TOOLS_DIR=$OUTPUT_DIR/tools
export ROOTFS_DIR=$OUTPUT_DIR/rootfs
export KERNEL_DIR=$OUTPUT_DIR/kernel
export IMAGES_DIR=$OUTPUT_DIR/image

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
total_build_time=$(timer)

rm -rf $IMAGES_DIR $BUILD_DIR
mkdir -pv $IMAGES_DIR $BUILD_DIR
echo '#!/bin/sh' > $BUILD_DIR/_fakeroot.fs
echo "set -e" >> $BUILD_DIR/_fakeroot.fs
echo "chown -h -R 0:0 $ROOTFS_DIR" >> $BUILD_DIR/_fakeroot.fs
echo "$TOOLS_DIR/sbin/mkfs.ext2 -d $ROOTFS_DIR $IMAGES_DIR/rootfs.ext2 130M" >> $BUILD_DIR/_fakeroot.fs
chmod a+x $BUILD_DIR/_fakeroot.fs
$TOOLS_DIR/usr/bin/fakeroot -- $BUILD_DIR/_fakeroot.fs
ln -svf rootfs.ext2 $IMAGES_DIR/rootfs.ext4
mkdir -pv $IMAGES_DIR/boot
cp -Rv $KERNEL_DIR/* $IMAGES_DIR/boot/
cp -v $SOURCES_DIR/{bootcode.bin,fixup4.dat,start4.elf} $IMAGES_DIR/boot/
echo "root=/dev/mmcblk0p2 rootwait console=tty1 console=ttyAMA0,115200" > $IMAGES_DIR/boot/cmdline.txt
cat > $IMAGES_DIR/boot/config.txt << "EOF"
# Please note that this is only a sample, we recommend you to change it to fit
# your needs.
# You should override this file using a post-build script.
# See http://buildroot.org/manual.html#rootfs-custom
# and http://elinux.org/RPiconfig for a description of config.txt syntax

kernel=Image

# To use an external initramfs file
#initramfs rootfs.cpio.gz

# Disable overscan assuming the display supports displaying the full resolution
# If the text shown on the screen disappears off the edge, comment this out
disable_overscan=1

# How much memory in MB to assign to the GPU on Pi models having
# 256, 512 or 1024 MB total memory
gpu_mem_256=100
gpu_mem_512=100
gpu_mem_1024=100

# fixes rpi (3B, 3B+, 3A+, 4B and Zero W) ttyAMA0 serial console
dtoverlay=miniuart-bt

# enable 64bits support
arm_64bit=1
EOF
cat > $BUILD_DIR/genimage.cfg << "EOF"
image boot.vfat {
  vfat {
    files = {
      "boot/bcm2711-rpi-4-b.dtb",
      "boot/bootcode.bin",
      "boot/cmdline.txt",
      "boot/config.txt",
      "boot/fixup4.dat",
      "boot/start4.elf",
      "boot/overlays",
      "boot/Image"
    }
  }
  size = 18M
}
image sdcard.img {
  hdimage {
  }
  partition boot {
    partition-type = 0xC
    bootable = "true"
    image = "boot.vfat"
  }
  partition rootfs {
    partition-type = 0x83
    image = "rootfs.ext4"
  }
}
EOF
$TOOLS_DIR/usr/bin/genimage \
--rootpath "$ROOTFS_DIR" \
--tmppath "$BUILD_DIR/genimage.tmp" \
--inputpath "$IMAGES_DIR" \
--outputpath "$IMAGES_DIR" \
--config "$BUILD_DIR/genimage.cfg"

success "\nTotal image build time: $(timer $total_build_time)\n"
