#!/bin/bash

NAME="vm-test-0"
# DRYRUN=true

VIRT_TYPE="kvm"
OS_TYPE="linux"
OS_VARIANT=""

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


get_network_options() {
    net=""
    [[ -n "$NETWORK_BRIDGE" ]] && net="${net}bridge="$NETWORK_BRIDGE","
    [[ -n "$NETWORK_PROFILE" ]] && net="${net}network="$NETWORK_PROFILE","
    [[ -n "$NETWORK_PORTGROUP" ]] && \
        net="${net}portgroup="$NETWORK_PORTGROUP","
    [[ -n "$NETWORK_MODEL" ]] && net="${net}model="$NETWORK_MODEL","

    [[ -n "$net" ]] && net="--network $net"
    echo $net
}

get_disk_options() {
    disk=""
    [[ -n "$DISK_BUS" ]] && disk="${disk}bus="$DISK_BUS","
    [[ -n "$DISK_CACHE" ]] && disk="${disk}cache="$DISK_CACHE","
    [[ -n "$DISK_FORMAT" ]] && disk="${disk}format=$DISK_FORMAT,"
    [[ -n "$DISK_PATH" ]] && disk="${disk}path="$DISK_PATH","
    [[ -n "$DISK_POOL" ]] && disk="${disk}pool="$DISK_POOL","
    [[ -n "$DISK_SHAREABLE" ]] && disk="${disk}shareable="$DISK_SHAREABLE","
    [[ -n "$DISK_SIZE" ]] && disk="${disk}size="$DISK_SIZE","

    [[ -n "$disk" ]] && disk="--disk $disk"
    echo $disk
}

get_os_options() {
    os_type=""
    os_variant=""
    [[ -n "$OS_TYPE" ]] && os_type="--os-type $OS_TYPE"
    [[ -n "$OS_VARIANT" ]] && os_variant="--os-type $OS_VARIANT"

    echo "$os_type $os_variant"
}

get_virt_type_options() {
    virt_type=""

    [[ -n "$VIRT_TYPE" ]] && virt_type="--virt-type $VIRT_TYPE"
    echo $virt_type
}

get_cpu_options() {
    cpu=""
    [[ -n "$CPU_MODE" ]] && cpu="${cpu}mode=$CPU_MODE,"
    [[ -n "$CPU_MODEL" ]] && cpu="${cpu}model=$CPU_MODEL,"

    [[ -n "$cpu" ]] && cpu="--cpu $cpu"

    echo $cpu
}

get_vcpu_options() {
    vcpus=""
    [[ -n "$VCPUS" ]] && vcpus="${vcpus}$VCPUS,"
    [[ -n "$MAX_VCPUS" ]] && vcpus="${vcpus}maxvcpus=$MAX_VCPUS,"

    [[ -n "$vcpus" ]] && vcpus="--vcpus $vcpus"

    echo "$vcpus"
}

get_memory_options() {
    memtune=""
    memory=""
    if [ -n "$MAX_MEMORY" ]
        then memtune="soft_limit="$MEMORY""
        memory="maxmemory="$MAX_MEMORY""
    else
        memory=""$MEMORY""
    fi

    [[ -n "$memtune" ]] && memtune="--memtune $memtune"
    [[ -n "$memory" ]] && memory="--memory $memory"

    echo "$memory $memtune"
}

virt_install_cmd="virt-install --name "$NAME" \
    --import \
    --noreboot \
    --video virtio \
    $(get_memory_options) \
    $(get_vcpu_options) \
    $(get_cpu_options) \
    $(get_disk_options) \
    $(get_virt_type_options) \
    $(get_network_options) \
    $(get_os_options) \
    "

if [ $DRYRUN ]
    then echo $virt_install_cmd
    exit
else
    eval $virt_install_cmd
fi

./install_arch.sh $NAME
