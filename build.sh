#!/bin/bash

set -euxo pipefail

make clean
make mrproper

RKBIN_DIR='/mnt/scratch2/rob/rkbin/bin'
# from https://github.com/armbian/build/blob/64f2d5f177e6365960cf4563bf19ad54e44f5a04/config/sources/families/include/rockchip64_common.inc
RKBIN_TOOLS='/mnt/scratch2/rob/rkbin/tools'
BOOT_USE_BLOBS=yes
BOOT_SUPPORT_SPI=yes
BOOT_SOC=rk3399
#DDR_BLOB='rk33/rk3399_ddr_933MHz_v1.20.bin' # 1GB model does not boot with later versions
DDR_BLOB='rk33/rk3399_ddr_933MHz_v1.24.bin'
# MINILOADER_BLOB='rk33/rk3399_miniloader_v1.19.bin'
MINILOADER_BLOB='rk33/rk3399_miniloader_v1.26.bin'
BL31_BLOB='rk33/rk3399_bl31_v1.35.elf'
UBOOT_TARGET_MAP=";;idbloader.bin uboot.img trust.bin"

if [[ $BOOT_SUPPORT_SPI == yes ]]; then
    UBOOT_TARGET_MAP="BL31=$RKBIN_DIR/$BL31_BLOB tpl/u-boot-tpl.bin spl/u-boot-spl.bin u-boot.itb ${UBOOT_TARGET_MAP} rkspi_loader.img"
fi

make rock-pi-4a-rk3399_defconfig
make -j$(getconf _NPROCESSORS_ONLN) CROSS_COMPILE=aarch64-linux-gnu-

# tools/mkimage -n $BOOT_SOC -T rksd -d $RKBIN_DIR/$DDR_BLOB idbloader.bin
# cat $RKBIN_DIR/$MINILOADER_BLOB >> idbloader.bin
# $RKBIN_TOOLS/loaderimage --pack --uboot ./u-boot-dtb.bin uboot.img 0x200000
# $RKBIN_TOOLS/trust_merger --replace bl31.elf $RKBIN_DIR/$BL31_BLOB trust.ini

#make spi
tools/mkimage -n $BOOT_SOC -T rkspi -d tpl/u-boot-tpl.bin:spl/u-boot-spl.bin rkspi_tpl_spl.img
dd if=/dev/zero of=rkspi_loader.img count=8128 status=none
dd if=rkspi_tpl_spl.img of=rkspi_loader.img conv=notrunc status=none
dd if=u-boot.itb of=rkspi_loader.img seek=768 conv=notrunc status=none

#to flash
# rkdeveloptool ld
# sudo rkdeveloptool db path/to/rk3399_loader_spinor_v1.15.114.bin
# sudo rkdeveloptool wl 0 rkspi_loader.img
# 