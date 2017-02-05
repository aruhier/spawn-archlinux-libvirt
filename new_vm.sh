#!/bin/bash
dir=$(dirname "$0")
set -e

### DEFAULT OPTIONS ###

DRYRUN=false

VIRT_TYPE="kvm"
OS_TYPE="linux"
OS_VARIANT=""

# In MiB
MEMORY="500"
MAX_MEMORY="1000"

CPU_MODE="host-passthrough"
CPU_MODEL=""
VCPUS="2"
MAX_VCPUS="4"

DISK_SIZE="5"
DISK_FORMAT="qcow2"
DISK_POOL="128g_kvm"
DISK_PATH=""
DISK_SHAREABLE="on"
DISK_CACHE="default"
DISK_BUS="virtio"

NETWORK_BRIDGE=""
NETWORK_PROFILE="ovs-lan"
NETWORK_PORTGROUP="trust"
NETWORK_MODEL="virtio"

AUTHORIZED_KEYS="""
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+j5HDc9fw2BtVqwXB8tO8MUDrva/VSbqv5+TSnUPWmYdW8guj+v1UzFK7wPYOHr/b4j9UVculFuB17niQS5HEh21vT7ogdKucHutLR0/zLKl43KFepr4dOVM5UEcnVbBng64kwlowLqpDjdSKnaysT3s0jHzMd/3xnY4yJ3UdYIl+lLtIeqvmFZssDR32E0q11M/JmotWaUcmBu2bHj4yWCjAWOxMTevNx57r6vLJM87Y/K3HKabQVtopfBs0Mr2l6uTZgxwPX47+gcO55Qho1oCwEUfFWWWg9oxMBVfgMny7UGzhLEbUIsmo7cxbzBA6lKSZzByptkZ9yMQapLVeiAOViTEfXeHOa4KfNln3cKg+VCCMS8YceSkZugFubuT6JGvnL+fB64oKI060wL7TLzm5bZ9nIqkMe/VtK0DI0wQ0LWbKCcB5PSP0DbJPuQM4ZEpDVWSea0mST4lUeTXpwIbPsTavp39RH4UudngVGA8fFmduLAQrbnAZS0zLgGIDg18zxIQlI/5WZ/N7kxl59J269XvaBoMKf0LR+tKa6IfOkZRiAaX2oIio1FAUZPdVtNhSfVhSN/t4osB7ObWRDb6JCUpYxot/tY42SxDXroUfhmKPim4+DrMrq11Xr+ckhDz50yRmrHwbP/Sc7Gt9IThjBlKaVPSnhpT4xxjP+w== anthony@gate.aruhier.fr
"""

SYSTEMD_NETWORKD_PROFILE="""
[Match]
Name=*

[Network]
DHCP=yes
"""

#######################


show_help() {
    echo "usage: $0 [-h] -n NAME"
    echo ""
    echo "Wrapper to create a kvm domain based on ArchLinux"
    echo ""
    echo "required arguments:"
    echo "    -n NAME, --name NAME   container name to create"
    echo ""
    echo "optional arguments:"
    echo "    -D, --dryrun  does not install the vm, just print the" \
       "virt-install command"
    echo "    -h, --help    show this help message and exit"
}


args=$(getopt -l "name:dryrun" -o "n:c:Dh" -- "$@")
eval set -- "$args"

while true ; do
    case "$1" in
        -n|--name)
            NAME="$2"
            shift 2
            ;;
        -D|--dryrun)
            DRYRUN=true
            shift
            ;;
        -h)
            show_help
            exit 0
            ;;
        --) shift ; break ;;
        *)
            echo "Invalid option: -$1" >&2
            show_help
            break
            ;;
    esac
done

if [ -z "$NAME" ]
    then show_help
    exit 1
fi

source $dir/src/virt_install_wrapper.sh
if $DRYRUN
    then echo `get_virt_install_command`
    exit
else
    eval `get_virt_install_command`
fi

source $dir/src/install_arch.sh
install_archlinux
