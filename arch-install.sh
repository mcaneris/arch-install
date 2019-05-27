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

ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
hwclock --systohc
echo en_US.UTF-8 >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 >> /etc/locale.conf
echo KEYMAP=en >> /etc/vconsole.conf
echo FONT=ter-v32n >> /etc/vconsole.conf
echo FONT_MAP=8859-2 >> /etc/vconsole.conf

read -p "\nEnter a name for this computer:" COMPUTER
cat <<EOT >> /etc/hostname
$COMPUTER
EOT

cat <<EOT >> /etc/hosts
"127.0.0.1  localhost"
""::1  localhost"
"127.0.1.1  $COMPUTER.localdomain $COMPUTER"
EOT

cat <<EOT >> /etc/mkinitcpio.conf
"MODULES=(ext4)"
"HOOKS=(base udev autodetect modconf block keyboard consolefont keymap encrypt lvm2 resume filesystems fsck)"
EOT
echo -e "\nRemember to remove duplicate lines from /etc/mkinitcpio.conf and execute mkinitcpio -p linux from the command line." 

# bootloader
bootctl --path=/boot install
cp loader.conf /boot/loader/loader.conf
cp arch.conf /boot/loader/entries/arch.conf
UUID=$(blkid $ROOT_PARTITION -sUUID -ovalue)
echo options cryptdevice=UUID=$UUID:lvm:allow-discards resume=/dev/mapper/arch-swap root=/dev/mapper/arch-root rw quiet >> /boot/loader/entries/arch.conf

# root password
passwd

# user setup
read -p "\nEnter username:" USERNAME
useradd -m -G audio,log,power,storage,video,wheel -s /bin/zsh $USERNAME
echo %wheel ALL=(ALL) ALL > /etc/sudoers
passwd mce

echo -e "Check files and perform missing operations now."
