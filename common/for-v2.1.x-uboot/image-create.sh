#!/bin/sh

BASEDIR="$(dirname $(realpath $0))"
SDBOOTIMG="$BASEDIR/../../../../rockdev/sdcard_full-for-v2.1.x-uboot.img"
KERNELIMG="$BASEDIR/../../../../rockdev/kernel-for-v2.1.x-uboot.img"
KERNELIMGDIR="$BASEDIR/../../../../rockdev/kernelimg"
UBOOTIMG="$BASEDIR/u-boot.img"
ROOTFSIMG="$BASEDIR/../../../../rockdev/rootfs.img"

#8331263 = 1024*1024*4000/512/139264
dd if=/dev/zero of=$SDBOOTIMG bs=512 count=8331263 conv=notrunc
cat << EOF | parted $SDBOOTIMG
mklabel msdos
unit s
mkpart primary fat32 8192 139263
mkpart primary ext4 139264 8331262
quit
EOF

dd if=$UBOOTIMG of=$SDBOOTIMG seek=64

# make kernel.img
dd if=/dev/zero of=$KERNELIMG bs=512 count=131072 conv=notrunc
mkfs.msdos  -i 4c892ded -F 32 $KERNELIMG
if [ ! -d $KERNELIMGDIR ];
then
    mkdir $KERNELIMGDIR
fi
sudo mount $KERNELIMG $KERNELIMGDIR
sudo cp $BASEDIR/../../../../kernel/arch/arm/boot/zImage $KERNELIMGDIR
sudo cp $BASEDIR/../../../../kernel/arch/arm/boot/dts/rk3288-tinker_board.dtb $KERNELIMGDIR
#sudo cp -r out/overlays/ out/kernelimg/overlays/
sudo cp $BASEDIR/boot/hw_intf.conf $KERNELIMGDIR
sudo cp -rf $BASEDIR/boot/extlinux $KERNELIMGDIR
#sudo cp -rf build/boot/wlan_preload.EXAMPLE out/kernelimg
sync
sudo umount $KERNELIMGDIR
dd if=$KERNELIMG of=$SDBOOTIMG bs=512 seek=8192 conv=notrunc

# copy rootfs
dd if=$ROOTFSIMG of=$SDBOOTIMG bs=512 seek=139264 conv=notrunc
