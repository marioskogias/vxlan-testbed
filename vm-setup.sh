#!/bin/bash

set -xe

echo "This is VM $1"

if [ $1 -eq 1 ];
then
	eth1ip=10.42.0.2/24
	redip=192.168.60.13/24
	redbridgeip=192.168.60.14
	remoteip1=10.42.0.3
	redmac="DE:AD:BE:EF:7B:01"
elif [ $1 -eq 2 ];
then
	eth1ip=10.42.0.3/24
	redip=192.168.60.15/24
	redbridgeip=192.168.60.16
	remoteip1=10.42.0.2
	redmac="DE:AD:BE:EF:7B:02"
else
	echo "Unknown numner"
	exit 1
fi

# Configure eth1
sudo ip addr add $eth1ip brd + dev eth1
sudo ip link set dev eth1 up

# Create namespace
sudo ip netns add red
sudo ip link add red-in type veth peer name red-out
sudo ip link set red-in netns red

# Give IP and MAC address
sudo ip netns exec red ip addr add $redip dev red-in
sudo ip netns exec red ip link set red-in address $redmac
sudo ip netns exec red ip link set red-in up

# Create bridge and connect interface
sudo ip link add bridge-main type bridge
sudo ip addr add $redbridgeip/24 dev bridge-main
sudo ip link set red-out master bridge-main
sudo ip link set red-out up
sudo ip link set bridge-main up

# Add default via the bridge
sudo ip netns exec red ip route add default via $redbridgeip

# Create vxlan tunner interface
# Do I need to give it an IP address?
sudo ip link add vxlan0 type vxlan id 42 dev eth1 remote $remoteip1 dstport 4789
sudo ip link set vxlan0 master bridge-main
sudo ip link set vxlan0 up

sudo sysctl -w net.ipv4.ip_forward=1
