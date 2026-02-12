echo "blacklist brcmfmac" | sudo tee /etc/modprobe.d/brcmfmac.conf
#cp grub.txt grub
#sudo rm /etc/default/grub
#sudo mv grub /etc/default/grub
cp ./brcmfmac.desktop ~/.config/autostart/
sudo grub-mkconfig -o /boot/grub/grub.cfg
echo "Setup done!"
