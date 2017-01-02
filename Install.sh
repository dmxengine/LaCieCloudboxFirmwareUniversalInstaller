#!/bin/bash
TARGET_DISK_DEV_NAME=/dev/sdb

command -v sgdisk >/dev/null 2>&1 || { echo "gdisk not installed. Type apt-get install gdisk. After installing try again" >&2; exit 1; }
command -v pvcreate >/dev/null 2>&1 || { echo "lvm2 not installed. Type apt-get install lvm2. After installing try again" >&2; exit 1; }
command -v mdadm >/dev/null 2>&1 || { echo "mdadm not installed. Type apt-get install mdadm. After installing try again" >&2; exit 1; }
command -v gunzip >/dev/null 2>&1 || { echo "gzip not installed. Type apt-get install gzip. After installing try again" >&2; exit 1; }

sgdisk --clear -g $TARGET_DISK_DEV_NAME
LAST_SECTOR=`sgdisk -E $TARGET_DISK_DEV_NAME`
sgdisk --disk-guid=48EB39C7-FA39-4315-9B4C-B7E4FE438E83 $TARGET_DISK_DEV_NAME
sgdisk --new=1:2048:4095 $TARGET_DISK_DEV_NAME
sgdisk --change-name=1:grub_core $TARGET_DISK_DEV_NAME
sgdisk --typecode=1:EF02 $TARGET_DISK_DEV_NAME

sgdisk --new=2:4096:397311 $TARGET_DISK_DEV_NAME
sgdisk --change-name=2:boot_rescue $TARGET_DISK_DEV_NAME
sgdisk --typecode=2:8300 $TARGET_DISK_DEV_NAME

sgdisk --new=3:397312:399359 $TARGET_DISK_DEV_NAME
sgdisk --change-name=3:nv_data $TARGET_DISK_DEV_NAME
sgdisk --typecode=3:8300 $TARGET_DISK_DEV_NAME

sgdisk --new=4:399360:3545087 $TARGET_DISK_DEV_NAME
sgdisk --change-name=4:root_1 $TARGET_DISK_DEV_NAME
sgdisk --typecode=4:FD00 $TARGET_DISK_DEV_NAME

sgdisk --new=5:3545088:6690815 $TARGET_DISK_DEV_NAME
sgdisk --change-name=5:root_2 $TARGET_DISK_DEV_NAME
sgdisk --typecode=5:FD00 $TARGET_DISK_DEV_NAME

sgdisk --new=6:6690816:8787967 $TARGET_DISK_DEV_NAME
sgdisk --change-name=6:var $TARGET_DISK_DEV_NAME
sgdisk --typecode=6:FD00 $TARGET_DISK_DEV_NAME

sgdisk --new=7:8787968:9312255 $TARGET_DISK_DEV_NAME
sgdisk --change-name=7:swap $TARGET_DISK_DEV_NAME
sgdisk --typecode=7:FD00 $TARGET_DISK_DEV_NAME

sgdisk --new=8:9312256:$LAST_SECTOR $TARGET_DISK_DEV_NAME
sgdisk --change-name=8:user_data $TARGET_DISK_DEV_NAME
sgdisk --typecode=8:FD00 $TARGET_DISK_DEV_NAME

gunzip -c sda1.dd-image.gz | dd of=${TARGET_DISK_DEV_NAME}1
gunzip -c sda2.dd-image.gz | dd of=${TARGET_DISK_DEV_NAME}2
gunzip -c sda3.dd-image.gz | dd of=${TARGET_DISK_DEV_NAME}3
gunzip -c sda4.dd-image.gz | dd of=${TARGET_DISK_DEV_NAME}4
gunzip -c sda5.dd-image.gz | dd of=${TARGET_DISK_DEV_NAME}5
gunzip -c sda6.dd-image.gz | dd of=${TARGET_DISK_DEV_NAME}6
gunzip -c sda7.dd-image.gz | dd of=${TARGET_DISK_DEV_NAME}7

mdadm --create --verbose /dev/md8 --level=mirror --metadata=1.0 --force --raid-devices=1 ${TARGET_DISK_DEV_NAME}8
pvcreate /dev/md8
vgcreate vg /dev/md8
lvcreate -l 100%FREE -n lv vg
mkfs.ext3 /dev/vg/lv
mkdir /lacie
mount /dev/vg/lv /lacie
tar -xzf archive.tar.gz -C /lacie
sync
umount /lacie
rm -r /lacie

