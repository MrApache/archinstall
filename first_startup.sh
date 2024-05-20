#yay
cd
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd && rm -rf yay

#Google chrome
yay -S --noconfirm google-chrome

sudo rm -rf /etc/rc.local