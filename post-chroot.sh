#!/bin/bash
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
