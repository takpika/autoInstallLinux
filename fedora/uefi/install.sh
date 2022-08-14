#!/bin/sh
#-----------
#Fedora自動インストーラー(UEFI形式) Intel/AMD 64bit(x86_64)
#使い方: sh install.sh <ユーザー名>
#インストール所要時間: 約3〜4分
#-----------
#設定エリア
HOSTNAME=fedora
VERSION=37
#-----------
#上級者向け設定
DISKNAME=sda
NEEDSWAP=true
SWAPSIZE=512M
#-----------

USER_NAME=$1

formatDisk () {
sudo umount -f /dev/$DISKNAME*
sudo dd if=/dev/zero of=/dev/$DISKNAME bs=1M count=1
sudo fdisk /dev/$DISKNAME << EOF
g
n
1

+64M
n
2


w
EOF
sleep 1
sudo mkfs.fat -F 32 /dev/${DISKNAME}1
sudo mkfs.ext4 /dev/${DISKNAME}2
sudo mkdir /mnt/root
sudo mount /dev/${DISKNAME}2 /mnt/root
}

downloadAndExtract () {
cd /mnt/root
if [ $VERSION -eq 37 ]; then
DATE=20220814.n.0
elif [ $VERSION -eq 36 ]; then
DATE=20220719.0
elif [ $VERSION -eq 35 ]; then
DATE=20220814.0
elif [ $VERSION -eq 34 ]; then
DATE=20220607.0
elif [ $VERSION -eq 31 ]; then
DATE=20190826.n.0
elif [ $VERSION -eq 30 ]; then
DATE=20190304.n.0
elif [ $VERSION -eq 29 ]; then
DATE=20180827.n.0
elif [ $VERSION -eq 28 ]; then
DATE=20180302.n.0
else
echo "Sorry, this version is not supported."
exit 1
fi
sudo curl -O https://kojipkgs.fedoraproject.org/packages/Fedora-Container-Base/${VERSION}/${DATE}/images/Fedora-Container-Base-${VERSION}-${DATE}.x86_64.tar.xz
sudo tar Jxfv Fedora-Container-Base-${VERSION}-${DATE}.x86_64.tar.xz
FOLDER=`find -name layer.tar | sed "s/\/layer.tar//g"`
sudo mv $FOLDER/layer.tar /mnt/root
sudo rm -rf $FOLDER repositories *.json *.tar.xz
sudo tar xvf layer.tar
sudo rm layer.tar
sudo mkdir -p /mnt/root/boot/efi
sudo mount /dev/${DISKNAME}1 /mnt/root/boot/efi
}

mountBind () {
sudo mount --bind /dev dev
sudo mount --bind /dev/pts dev/pts
sudo mount --bind /proc proc
sudo mount --bind /sys sys
sudo mount --bind /etc/resolv.conf etc/resolv.conf
}

installDnf () {
sudo chroot /mnt/root dnf install kernel kernel-core kernel-headers kernel-modules grub2-efi-x64 grub2-efi-x64-modules efibootmgr systemd dhcpcd sudo passwd -y
sudo chroot /mnt/root systemctl enable dhcpcd
}

setHost() {
sudo tee /mnt/root/etc/hostname << EOF
$HOSTNAME
EOF
sudo tee /mnt/root/etc/hosts << EOF
127.0.0.1 $HOSTNAME
EOF
}

setMount () {
sudo tee /mnt/root/etc/fstab << EOF
/dev/${DISKNAME}2 / ext4 errors=remount-ro 0 1
/dev/${DISKNAME}1 /boot/efi vfat umask=0077 0 1
EOF
if "${NEEDSWAP}"; then
sudo chroot /mnt/root fallocate -l $SWAPSIZE /swapfile
sudo chroot /mnt/root chmod 600 /swapfile
sudo chroot /mnt/root /usr/sbin/mkswap /swapfile
sudo tee -a /mnt/root/etc/fstab << EOF
/swapfile none swap sw 0 0
EOF
fi
}

createUser () {
sudo chroot /mnt/root /usr/sbin/useradd $USER_NAME -d /home/$USER_NAME -s /bin/bash -u 1000
sudo chroot /mnt/root /usr/bin/passwd -d $USER_NAME
sudo chroot /mnt/root mkdir /home/$USER_NAME
sudo chroot /mnt/root chown -R $USER_NAME /home/$USER_NAME
sudo chroot /mnt/root chmod -R 750 /home/$USER_NAME
sudo chroot /mnt/root /usr/sbin/usermod -G wheel $USER_NAME
}

installGrub () {
cp /mnt/root/boot/efi/EFI/fedora/grubx64.efi /mnt/root/boot/efi/EFI/BOOT/BOOTx64.efi
}

setPasswordConf () {
tee /mnt/root/home/$USER_NAME/.bash_profile << EOF
echo "Please set your password"
while ! passwd; do
echo 'failure. retry...'
done
rm ~/.bash_profile
EOF
sudo chroot /mnt/root chown $USER_NAME /home/$USER_NAME/.bash_profile
}

finish () {
printf "Installation finished. Do you want to reboot now? [Y/n] "
read CMDR
if [ "$CMDR" = "y" ];then
sudo reboot
elif [ "$CMDR" = "Y" ];then
sudo reboot
fi
}

main () {
formatDisk
downloadAndExtract
mountBind
installDnf
setHost
setMount
createUser
setPasswordConf
installGrub
finish
}

main