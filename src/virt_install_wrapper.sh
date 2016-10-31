#!/bin/bash

get_virt_install_command() {
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

    echo $virt_install_cmd
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

get_vcpu_options() {
    vcpus=""
    [[ -n "$VCPUS" ]] && vcpus="${vcpus}$VCPUS,"
    [[ -n "$MAX_VCPUS" ]] && vcpus="${vcpus}maxvcpus=$MAX_VCPUS,"

    [[ -n "$vcpus" ]] && vcpus="--vcpus $vcpus"

    echo "$vcpus"
}

get_cpu_options() {
    cpu=""
    [[ -n "$CPU_MODE" ]] && cpu="${cpu}mode=$CPU_MODE,"
    [[ -n "$CPU_MODEL" ]] && cpu="${cpu}model=$CPU_MODEL,"

    [[ -n "$cpu" ]] && cpu="--cpu $cpu"

    echo $cpu
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

get_virt_type_options() {
    virt_type=""

    [[ -n "$VIRT_TYPE" ]] && virt_type="--virt-type $VIRT_TYPE"
    echo $virt_type
}

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

get_os_options() {
    os_type=""
    os_variant=""
    [[ -n "$OS_TYPE" ]] && os_type="--os-type $OS_TYPE"
    [[ -n "$OS_VARIANT" ]] && os_variant="--os-type $OS_VARIANT"

    echo "$os_type $os_variant"
}
