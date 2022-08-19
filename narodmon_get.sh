#!/bin/sh

# fake "get data" for initialization
digitemp_DS9097 -q -i -a -s /dev/ttyUSB0 >/dev/nul

# get heading
NAME=`uname -n`
MAC=`cat /sys/class/net/eth1/address`

# add heading
echo "#$MAC#$NAME" >> /var/log/narodmon1

# get data
RX=`cat /sys/class/net/eth1/statistics/rx_bytes`
TX=`cat /sys/class/net/eth1/statistics/tx_bytes`
TIME=$(date -I"seconds")
CELSIUS=$(digitemp_DS9097 -q -i -a -s /dev/ttyUSB0 | awk '{FS=" "; if($2==":") { mac[NR-1]=$1;}; if($4=="Sensor") { print "#"mac[$5]"#"$7;}}')

# add data 
echo "$CELSIUS#$TIME" >> /var/log/narodmon1
echo "#$MAC:RX#$RX#$TIME" >> /var/log/narodmon1
echo "#$MAC:TX#$TX#$TIME" >> /var/log/narodmon1

# add ending "##"
echo "$(sed '/##/d' /var/log/narodmon1 | awk '!($0 in a) {a[$0];print}')" > /var/log/narodmon1
echo "##" >> /var/log/narodmon1
