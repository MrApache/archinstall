#!/bin/bash
#yay
cd
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd && rm -rf yay

#Google chrome
yay -S --noconfirm google-chrome

systemctl stop startup.service
sudo rm -rf /etc/systemd/system/startup.service
sudo rm -rf /home/irisu/first_startup.sh
exit 0