#!/bin/bash

set -xe

echo "This is VM $1"

multicastip=225.42.42.42

if [ $1 -eq 1 ];
then
	eth1ip=10.42.0.2/24
	redip=192.168.60.13/24
	remoteredip1=192.168.60.15
	remoteredip2=192.168.60.17
	redbridgeip=192.168.60.14
	remoteip1=10.42.0.3
	remoteip2=10.42.0.4
	redmac="DE:AD:BE:EF:7B:01"
	remoteredmac1="DE:AD:BE:EF:7B:02"
	remoteredmac2="DE:AD:BE:EF:7B:03"
elif [ $1 -eq 2 ];
then
	eth1ip=10.42.0.3/24
	redip=192.168.60.15/24
	remoteredip1=192.168.60.13
	remoteredip2=192.168.60.17
	redbridgeip=192.168.60.16
	remoteip1=10.42.0.2
	remoteip2=10.42.0.4
	redmac="DE:AD:BE:EF:7B:02"
	remoteredmac1="DE:AD:BE:EF:7B:01"
	remoteredmac2="DE:AD:BE:EF:7B:03"
elif [ $1 -eq 3 ];
then
	eth1ip=10.42.0.4/24
	redip=192.168.60.17/24
	remoteredip1=192.168.60.13
	remoteredip2=192.168.60.15
	redbridgeip=192.168.60.18
	remoteip1=10.42.0.2
	remoteip2=10.42.0.3
	redmac="DE:AD:BE:EF:7B:03"
	remoteredmac1="DE:AD:BE:EF:7B:01"
	remoteredmac2="DE:AD:BE:EF:7B:03"
else
	echo "Unknown number"
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

# Create vxlan tunner interface with multicast
sudo ip link add vxlan0 type vxlan id 42 dev eth1 dstport 4789 nolearning
sudo ip link set vxlan0 master bridge-main
sudo ip link set vxlan0 up

# Configure static arp and add fdb rules
# Can you do it without static ARP entries?
sudo ip netns exec red arp -i red-in -s $remoteredip1 $remoteredmac1
sudo ip netns exec red arp -i red-in -s $remoteredip2 $remoteredmac2
bridge fdb append $remoteredmac1 dev vxlan0 dst $remoteip1
bridge fdb append $remoteredmac2 dev vxlan0 dst $remoteip2

sudo sysctl -w net.ipv4.ip_forward=1
