#!/bin/bash
wget http://download.virtualbox.org/virtualbox/6.0.20/VBoxGuestAdditions_6.0.20.iso
sudo mount -o loop VBoxGuestAdditions_6.0.20.iso /mnt
cd /mnt
sudo sh VBoxLinuxAdditions.run --nox11
echo ">>>> Step 2 already complete! <<<<"
