#!/bin/bash

set -xe

mem=2048
base_cow=/home/marioskogias/vxlan-tests/vmdisk.qcow2
script=/home/marioskogias/vxlan-tests/qemu-ifup

run_vm() {
	private_cow=/home/marioskogias/vxlan-tests/private"$1".qcow2
	mac=DE:AD:BE:EF:D9:0"$1"

	if [ ! -f "$private_cow" ]; then
		echo "$0: Private file '$private_cow' not found." 1>&2

		if [ ! -e "$base_cow" ]; then
			echo "$0: '$base_cow' does not exist." 1>&2
			echo "Please specify an existing backing qcow2 filename." 1>&2
			exit 1
		fi
		echo "Creating file '$private_cow', backed by '$base_cow'" 1>&2
		qemu-img create -f qcow2 -F qcow2 -b "$base_cow" "$private_cow"
	fi

	sudo qemu-system-x86_64 \
		-m $mem \
		-smp 2 \
		-drive file=$private_cow \
		-enable-kvm \
		-device virtio-net-pci,netdev=net0 \
		-netdev user,id=net0,hostfwd=tcp::222$1-:22 \
		-device e1000,netdev=net1,mac=$mac \
		-netdev tap,id=net1,script=$script \
		-display none &
}

run_vm 1
run_vm 2
