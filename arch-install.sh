#!/bin/bash
# This script expects the partitions to be ready.
pacman -S terminus-font
setfont ter-v32n -m 8859-2
read -p "\nEnter partition to install (i.e. /dev/nvme0n1pX):" ROOT_PARTITION
timedatectl set-ntp true
cryptsetup -c aes-xts-plain64 -h sha512 -s 512 --use-random luksFormat $ROOT_PARTITION
cryptsetup open $ROOT_PARTITION arch-lvm

pvcreate /dev/mapper/arch-lvm
vgcreate arch /dev/mapper/arch-lvm
read -p "\nEnter swap size (i.e. 8G):" SWAP_SIZE
lvcreate -L +$SWAP_SIZE arch -n swap
lvcreate -l +100%FREE arch -n root

mkfs.ext4 /dev/mapper/arch-root
mkswap /dev/mapper/arch-swap
swapon /dev/mapper/arch-swap

mount /dev/mapper/arch-root /mnt
mkdir /mnt/boot

read -p "\nEnter EFI partition (i.e. /dev/nvme0n1pX):" BOOT_PARTITION
mount $BOOT_PARTITION /mnt/boot

pacstrap /mnt base base-devel vim wpa_supplicant dialog intel-ucode terminus-font zsh git
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
