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
timedatectl set-timezone $TIME


parted -s $DISK mklabel gpt

parted -s $DISK mkpart primary fat32 1MiB 513MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary linux-swap 513MiB 4GiB
parted -s $DISK mkpart primary btrfs 4GiB 100%

mkfs.fat -F 32 /dev/sda1
mkswap /dev/sda2
mkfs.btrfs /dev/sda3

mount /dev/sda3 /mnt
mkdir -p /mnt/boot/EFI
mount /dev/sda1 /mnt/boot/EFI
swapon $SWAP

pacstrap -K /mnt base linux linux-firmware neovim grub efibootmgr os-prober
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash -e << EOF
#mkdir /boot/efi
#grub-install --efi-directory=/boot/efi --target=x86_64-efi $DISK
#grub-mkconfig -o /boot/grub/grub.cfg
ln -sf /usr/share/zoneinfo/$TIME /etc/localtime
hwclock --systohc

sed -i -e 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
sed -i -e 's/#ru_RU.UTF-8/ru_RU.UTF-8/g' /etc/locale.gen
locale-gen
printf 'LANG=ru_RU.UTF-8' > /etc/locale.conf
printf $HOSTNAME > /etc/hostname

echo "root:$ROOTPASS" | chpasswd
useradd -m $USERNAME
echo "$USERNAME:$USERPASS" | chpasswd
EOF