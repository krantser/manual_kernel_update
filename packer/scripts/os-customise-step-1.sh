#!/bin/bash
yum makecache
sudo yum -y install ncurses-devel make gcc bc openssl-devel bison
sudo yum -y install elfutils-libelf-devel rpm-build wget flex
sudo yum -y install hmaccalc zlib-devel binutils-devel rsync
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.36.tar.xz
tar -xf linux-5.4.36.tar.xz
cp /boot/config-3.10* linux-5.4.36/.config
cd linux-5.4.36/
make olddefconfig
make rpm-pkg
sudo rpm -iUv ~/rpmbuild/RPMS/x86_64/*.rpm
echo ">>>> Step 1 already complete! <<<<"
sudo reboot
