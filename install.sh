#!/bin/bash
echo "Enter hostname:"
read HOSTNAME

echo "Enter username:"
read USERNAME

echo "Enter user password:"
read USERPASS

echo "Enter root password:"
read ROOTPASS

echo "Enter /dev/DISK:"
read DISK

TIME="Europe/Samara"
EFI="${DISK}1"
SWAP="${DISK}2"
ROOT="${DISK}3"

timedatectl set-timezone $TIME

parted --script $DISK \
	mklabel gpt \
	mkpart "efi" fat32 1MiB 261MiB \
	set 1 esp on \
	mkpart "swap" linux-swap 261MiB 4G \
	mkpart "linux" btrfs 4G 100%

mkfs.fat -F 32 $EFI
mkswap $SWAP
mkfs.btrfs $ROOT

mount $ROOT /mnt
mount --mkdir $EFI /mnt/boot
swapon $SWAP

pacstrap -K /mnt base linux linux-firmware neovim
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash -e << EOF
ln -sf /usr/share/zoneinfo/$TIME /etc/localtime
hwclock --systohc

#(нужно отредактировать /etc/locale.gen)
#(удалить символ # у ru и en локалей)
sed -i -e 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
sed -i -e 's/#ru_RU.UTF-8/ru_RU.UTF-8/g' /etc/locale.gen
locale-gen
printf 'LANG=ru_RU.UTF-8' > /etc/locale.conf
printf $HOSTNAME > /etc/hostname

echo $ROOTPASS | passwd
useradd -m $USERNAME
echo $USERPASS | passwd $USERNAME
EOF