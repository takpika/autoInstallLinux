#!/bin/sh
#-----------
#Ubuntu自動インストーラー(Legacy・BIOS形式) Intel/AMD 64bit(x86_64)
#使い方: sh install.sh <ユーザー名> <パスワード>
#インストール所要時間: 約3〜4分
#-----------
#設定エリア
HOSTNAME=ubuntu
VERSION=22.04
#-----------
#上級者向け設定
DISKNAME=sda
NEEDSWAP=true
SWAPSIZE=512M
KERNEL_VERSION=5.15.0-46
#-----------

USER_NAME=$1
USER_PASS=password

formatDisk () {
sudo fdisk /dev/$DISKNAME << EOF
o
n
p
1


w
EOF
sleep 1
sudo mkfs.ext4 /dev/${DISKNAME}1
sudo mkdir /mnt/root
sudo mount /dev/${DISKNAME}1 /mnt/root
}

downloadAndExtract () {
cd /mnt/root
sudo curl -O https://cdimage.ubuntu.com/ubuntu-base/releases/$VERSION/release/ubuntu-base-$VERSION-base-amd64.tar.gz
sudo tar xzvf ubuntu-base-$VERSION-base-amd64.tar.gz
sudo rm ubuntu-base-$VERSION-base-amd64.tar.gz
}

mountBind () {
sudo mount --bind /dev dev
sudo mount --bind /dev/pts dev/pts
sudo mount --bind /proc proc
sudo mount --bind /sys sys
sudo mount --bind /etc/resolv.conf etc/resolv.conf
}

installApt () {
sudo chroot /mnt/root apt update
sudo chroot /mnt/root apt install linux-image-${KERNEL_VERSION}-generic linux-headers-${KERNEL_VERSION}-generic linux-modules-${KERNEL_VERSION}-generic systemd systemd-sysv init dhcpcd5 sudo -y
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
/dev/${DISKNAME}1 / ext4 errors=remount-ro 0 1
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
sudo chroot /mnt/root perl -e "print(crypt('$USER_PASS', 'wtf'));" > ~/.pass
sudo chroot /mnt/root /usr/sbin/useradd $USER_NAME -p `cat ~/.pass` -d /home/$USER_NAME -s /bin/bash -u 1000
sudo chroot /mnt/root mkdir /home/$USER_NAME
sudo chroot /mnt/root chown -R $USER_NAME /home/$USER_NAME
sudo chroot /mnt/root /usr/sbin/usermod -G sudo $USER_NAME
}

installGrub () {
sudo chroot /mnt/root /usr/sbin/grub-install --target=i386-pc /dev/$DISKNAME
sudo chroot /mnt/root /usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg
}

main () {
formatDisk
downloadAndExtract
mountBind
installApt
setHost
setMount
createUser
installGrub
sudo reboot
}

main
