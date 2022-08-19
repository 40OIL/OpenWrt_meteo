#!/bin/sh

# fake "get data" for initialization
digitemp_DS9097 -q -i -a -s /dev/ttyUSB0 >/dev/nul

# get heading
NAME=`uname -n`
MAC=`cat /sys/class/net/eth1/address`
EMAIL_TO='email@to.send.errors'

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

# lenght of file >0
LC=`cat /var/log/narodmon1 | wc -l`
if [ $LC -lt 2 ]; then
   echo -e "$TIME  size is 0 bytes\n"  >> /var/log/narodmon_error
   exit 1
fi

# lenght of file <4000
maxsize=4000
actualsize=$(wc -c <"/var/log/narodmon1")
if [ $actualsize -ge $maxsize ]; then
   echo -e "$TIME  size is $actualsize bytes\n"  >> /var/log/narodmon_error
   # copy datafile to narodmon#$TIME
   cp /var/log/narodmon1 /var/log/narodmon#$TIME
   # clear datafile
   cp /dev/null /var/log/narodmon1
   # email to user
   echo "narodmon filesize is $actualsize bytes" | ssmtp $EMAIL_TO
   exit 1
fi

# site is pinging?
ping -4 -c 3 narodmon.ru >nul
if [ $? -gt 0 ]; then
   echo -e "$TIME  narodmon.ru DOES NOT RESPOND\n" >> /var/log/narodmon_error
   exit 1
fi

# sending 2-pass
run2=1st
for i in 1 2
   do
      # send datafile
      RESULT=$(cat /var/log/narodmon1 | nc narodmon.ru 8283)
      # sending time
      TIME=$(date -I"seconds")

      # logging 2nd pass result
      if [ "$run2" == "2nd" ]; then
         echo -e "$run2  $TIME  RESULT=$RESULT\n" >> /var/log/narodmon_error
      fi

      # if OK
      if [ "$RESULT" == "OK" ]; then
         # clear datafile
         cp /dev/null /var/log/narodmon1
         break
      fi

      # if errors
      echo -e "$run2  $TIME  RESULT=$RESULT\n" >> /var/log/narodmon_error

      # if datafile damaged
      if echo "$RESULT" | grep -q damaged ; then
         # copy datafile to narodmon#$TIME
         cp /var/log/narodmon1 /var/log/narodmon#$TIME
         # clear datafile
         cp /dev/null /var/log/narodmon1
         # email to user
         echo "narodmon sending result is $RESULT" | ssmtp $EMAIL_TO
         break
      fi 

      run2=2nd
      # pause 130 sec
      ping  -4 -c 130 -i 1 127.0.0.1 >nul
   done
exit 1
