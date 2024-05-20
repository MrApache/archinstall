#!/bin/bash
setfont cyr-sun16

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
HOME_DIR="/home/$USERNAME" 
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

pacstrap -K /mnt base linux linux-firmware base-devel git
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash -e << EOF

#TIME
ln -sf /usr/share/zoneinfo/$TIME /etc/localtime
hwclock --systohc

#Locale
sed -i -e 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
sed -i -e 's/#ru_RU.UTF-8/ru_RU.UTF-8/g' /etc/locale.gen
locale-gen
printf 'KEYMAP=ru\nFONT=cyr-sun16' >> /etc/vconsole.conf
printf 'LANG=ru_RU.UTF-8' > /etc/locale.conf

#HOSTNAME
printf $HOSTNAME > /etc/hostname

#USER
echo "root:$ROOTPASS" | chpasswd
useradd -m $USERNAME
echo "$USERNAME:$USERPASS" | chpasswd

#AUR packages

#configs
cd $HOME_DIR
git clone https://github.com/MrApache/archinstall.git
yes | cp -rf $HOME_DIR/archinstall/pacman.conf /etc/pacman.conf
yes | mv $HOME_DIR/archinstall/first_startup.sh $HOME_DIR/first_startup.sh
yes | mv $HOME_DIR/startup.service /etc/systemd/system/startup.service
rm -rf archinstall
pacman -Sy

systemctl enable startup.service

pacman -S --noconfirm mesa lib32-mesa amdvlk lib32-amdvlk sudo man-db man-pages-ru networkmanager neovim grub efibootmgr os-prober hyprland kitty 

#AUTOSTART
systemctl enable NetworkManager
printf '$USERNAME ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers

#GRUB
grub-install $DISK
grub-mkconfig -o /boot/grub/grub.cfg
EOF
reboot