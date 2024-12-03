#!/bin/bash

set -ex

bridge=br0
inf0=veth0
inf1=veth1

### Remove the veth
if ip link show $inf0 &> /dev/null; then
	ip link delete $inf0 type veth
fi

### Remove the bridge
if ip link show $bridge &> /dev/null; then
	ip link set dev $bridge down
	brctl delbr $bridge
fi
