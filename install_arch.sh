#!/bin/bash

NAME=$1
DISK_TYPE="qcow2"
MOUNT_POINT="/mnt/archinstall"

AUTHORIZED_KEYS="""
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+j5HDc9fw2BtVqwXB8tO8MUDrva/VSbqv5+TSnUPWmYdW8guj+v1UzFK7wPYOHr/b4j9UVculFuB17niQS5HEh21vT7ogdKucHutLR0/zLKl43KFepr4dOVM5UEcnVbBng64kwlowLqpDjdSKnaysT3s0jHzMd/3xnY4yJ3UdYIl+lLtIeqvmFZssDR32E0q11M/JmotWaUcmBu2bHj4yWCjAWOxMTevNx57r6vLJM87Y/K3HKabQVtopfBs0Mr2l6uTZgxwPX47+gcO55Qho1oCwEUfFWWWg9oxMBVfgMny7UGzhLEbUIsmo7cxbzBA6lKSZzByptkZ9yMQapLVeiAOViTEfXeHOa4KfNln3cKg+VCCMS8YceSkZugFubuT6JGvnL+fB64oKI060wL7TLzm5bZ9nIqkMe/VtK0DI0wQ0LWbKCcB5PSP0DbJPuQM4ZEpDVWSea0mST4lUeTXpwIbPsTavp39RH4UudngVGA8fFmduLAQrbnAZS0zLgGIDg18zxIQlI/5WZ/N7kxl59J269XvaBoMKf0LR+tKa6IfOkZRiAaX2oIio1FAUZPdVtNhSfVhSN/t4osB7ObWRDb6JCUpYxot/tY42SxDXroUfhmKPim4+DrMrq11Xr+ckhDz50yRmrHwbP/Sc7Gt9IThjBlKaVPSnhpT4xxjP+w== anthony@gate.aruhier.fr
"""

SYSTEMD_NETWORKD_PROFILE="""
[Match]
Name=*

[Network]
DHCP=yes
"""


if [ -z "$NAME" ]
    then exit 1
fi

disk_path=`virsh domblklist "$NAME" | grep vda | awk {'print $2'}`
echo $disk_path

# attach disk
if [ "$DISK_TYPE" = "qcow2" ]
    then modprobe nbd max_part=63
    dev_disk=/dev/nbd0
    qemu-nbd -c $dev_disk "$disk_path"
    partx -a $dev_disk
elif [ "$DISK_TYPE" = "raw" ]
    then dev_disk=`losetup -f --show "$disk_path"`
    partx -a $dev_disk
else
    echo "Do not know how to mount the disk, exit"
    exit 1
fi
echo $dev_disk


sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${dev_disk}
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # empty
    # empty
  a 1 # make a partition bootable
    # empty
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

partprobe
partx -a $dev_disk
if [ "$DISK_TYPE" = "raw" ]
    then partx -a $dev_disk
fi

# Error with syslinux (failed to load ldlinux.c32) without the ^64bit option
mkfs.ext4 -O "^64bit" ${dev_disk}p1
mkdir -p "$MOUNT_POINT"
mount ${dev_disk}p1 "$MOUNT_POINT"

pacstrap -c "$MOUNT_POINT" base base-devel openssh python2 syslinux
arch-chroot "$MOUNT_POINT" \
    systemctl enable sshd systemd-networkd systemd-resolved

mkdir -p "$MOUNT_POINT/root/.ssh"
chmod 700 "$MOUNT_POINT/root/.ssh"
echo "$AUTHORIZED_KEYS" >> "$MOUNT_POINT/root/.ssh/authorized_keys"
chmod 600 "$MOUNT_POINT/root/.ssh"
echo "$SYSTEMD_NETWORKD_PROFILE" > \
    "$MOUNT_POINT/etc/systemd/network/eth0.network"
rm "$MOUNT_POINT"/etc/resolv.conf
ln -s /run/systemd/resolve/resolv.conf "$MOUNT_POINT"/etc/resolv.conf

# install syslinux
arch-chroot "$MOUNT_POINT" /usr/bin/syslinux-install_update -i -a -m
cat syslinux.cfg > "$MOUNT_POINT"/boot/syslinux/syslinux.cfg

cat mkinitcpio.conf > "$MOUNT_POINT"/etc/mkinitcpio.conf
arch-chroot "$MOUNT_POINT" mkinitcpio -p linux

# Enable tty via serial to be compatible with the `virsh console` command
arch-chroot "$MOUNT_POINT" systemctl enable getty@ttyS0

# detach disk
umount "$MOUNT_POINT"
sync
if [ "$DISK_TYPE" = "qcow2" ]
    then qemu-nbd -d $dev_disk
elif [ "$DISK_TYPE" = "raw" ]
    then partx -d ${dev_disk}p*
    losetup -d $dev_disk
fi

echo ""
echo "### INSTALLATION DONE ###"
echo ""
