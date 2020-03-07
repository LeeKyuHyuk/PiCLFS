# Cross Linux From Scratch (CLFS) on the Raspberry Pi 4

Cross Linux From Scratch (CLFS) is a project that provides you with step-by-step instructions for building your own customized Linux system entirely from source.

**There is no root password. Use `passwd` to change the root password.**

### Preparing Build Environment

Debian 9 or Ubuntu 18.04 is recommended.

``` bash
sudo apt update
sudo apt install gcc g++ make wget
```

### Step 1) Download All The Packages

``` bash
./01-download-packages.sh
```

### Step 2) Build Toolchain

``` bash
./02-build-toolchain.sh
```

```
$ aarch64-linux-gnu-gcc --version
aarch64-linux-gnu-gcc (GCC) 9.2.0
Copyright (C) 2019 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

### Step 3) Build Root File System

``` bash
./03-build-root-file-system.sh
```

### Step 4) Build Kernel

``` bash
./04-build-kernel.sh
```

### Step 5) Generate PiCLFS sdcard image

``` bash
./05-generate-image.sh
```

### How to installing PiCLFS image


```bash
sudo dd if=out/image/sdcard.img of=/dev/sdX bs=4M
sync
```

### Thanks to

- [Buildroot](https://buildroot.org)
- [Cross Linux From Scratch (CLFS)](http://clfs.org)
- [PiLFS](http://www.intestinate.com/pilfs/)
