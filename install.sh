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

#make_partitions()
#{
#	parted
#	echo "Continue[y/n]?"
#	read ANSWER
#	if [ "$ANSWER" != "y" ]; then
#		make_partitions
#	fi
#}

#make_partitions

parted -s $DISK mklabel gpt

# Создаем первый раздел (например, EFI раздел, размером 512MiB)
parted -s $DISK mkpart primary fat32 1MiB 513MiB
parted -s $DISK set 1 esp on

# Создаем второй раздел (например, корневой раздел, размером 20GiB)
parted -s $DISK mkpart primary ext4 513MiB 20.5GiB

# Создаем третий раздел (например, раздел подкачки, размером 4GiB)
parted -s $DISK mkpart primary linux-swap 20.5GiB 24.5GiB

# Создаем четвертый раздел (например, раздел /home, на оставшееся пространство)
parted -s $DISK mkpart primary ext4 24.5GiB 100%

echo "Enter EFI partition:"
read EFI

echo "Enter swap partition:"
read SWAP

echo "Enter root partition:"
read ROOT

mkfs.fat -F 32 $EFI
mkswap $SWAP
mkfs.btrfs $ROOT

mount $ROOT /mnt
mount --mkdir $EFI /mnt/boot
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