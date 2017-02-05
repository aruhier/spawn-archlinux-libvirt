#!/bin/bash

MOUNT_POINT="/mnt/archinstall"

install_archlinux() {
    disk_path=`get_domain_disk_vda_path`
    # mount our disk as dev_disk
    dev_disk=`attach_disk $disk_path`

    trap "global_trap $dev_disk" ERR

    partition_disk $dev_disk
    format_first_partition_in_ext $dev_disk
    mount_root_partition $dev_disk

    install_pkg
    enable_systemd_services
    add_ssh_keys
    enable_dhcp_with_systemd_networkd

    setup_syslinux
    build_kernel_img
    enable_serial_tty

    detach_disk $dev_disk

    echo ""
    echo "### INSTALLATION DONE ###"
    echo ""
}

global_trap() {
    dev_disk=$1

    set +e
    >&2 echo "An error occured, stopping installation and detaching disk"
    detach_disk $dev_disk
    set -e
}

get_domain_disk_vda_path() {
    disk_path=`virsh domblklist "$NAME" | grep vda | awk {'print $2'}`
    echo $disk_path
}

attach_disk() {
    disk_path=$1

    if [ "$DISK_FORMAT" = "qcow2" ]
        then modprobe nbd max_part=63
        dev_disk=/dev/nbd0
        qemu-nbd -c $dev_disk "$disk_path"
    elif [ "$DISK_FORMAT" = "raw" ]
        then dev_disk=`losetup -f --show "$disk_path"`
        partx -a $dev_disk
    else
        echo "Do not know how to mount the disk, exit"
        exit 1
    fi

    echo $dev_disk
}

partition_disk() {
    dev_disk=$1

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
}

format_first_partition_in_ext() {
    dev_disk=$1

    # Error with syslinux (failed to load ldlinux.c32) without the ^64bit
    # option
    mkfs.ext4 -O "^64bit" ${dev_disk}p1
}

mount_root_partition() {
    dev_disk=$1

    mkdir -p "$MOUNT_POINT"
    mount ${dev_disk}p1 "$MOUNT_POINT"
}

install_pkg() {
    pacstrap -c "$MOUNT_POINT" base base-devel openssh python2 syslinux haveged
}

enable_systemd_services() {
    arch-chroot "$MOUNT_POINT" \
        systemctl enable sshd systemd-networkd systemd-resolved haveged \
            getty@ttyS0
}

add_ssh_keys() {
    mkdir -p "$MOUNT_POINT/root/.ssh"
    chmod 700 "$MOUNT_POINT/root/.ssh"
    echo "$AUTHORIZED_KEYS" >> "$MOUNT_POINT/root/.ssh/authorized_keys"
    chmod 600 "$MOUNT_POINT/root/.ssh"
}

enable_dhcp_with_systemd_networkd() {
    echo "$SYSTEMD_NETWORKD_PROFILE" > \
        "$MOUNT_POINT/etc/systemd/network/eth0.network"
    rm "$MOUNT_POINT"/etc/resolv.conf
    ln -s /run/systemd/resolve/resolv.conf "$MOUNT_POINT"/etc/resolv.conf
}

setup_syslinux() {
    arch-chroot "$MOUNT_POINT" /usr/bin/syslinux-install_update -i -a -m
    cat "$dir"/conf/syslinux.cfg > "$MOUNT_POINT"/boot/syslinux/syslinux.cfg
}

build_kernel_img() {
    cat "$dir"/conf/mkinitcpio.conf > "$MOUNT_POINT"/etc/mkinitcpio.conf
    arch-chroot "$MOUNT_POINT" mkinitcpio -p linux
}

enable_serial_tty() {
    # Enable tty via serial to be compatible with the `virsh console` command
    arch-chroot "$MOUNT_POINT" systemctl enable getty@ttyS0
}

detach_disk() {
    dev_disk=$1

    umount "$MOUNT_POINT"
    sync
    if [ "$DISK_FORMAT" = "qcow2" ]
        then qemu-nbd -d $dev_disk
    elif [ "$DISK_FORMAT" = "raw" ]
        then partx -d ${dev_disk}p*
        losetup -d $dev_disk
    fi
}
