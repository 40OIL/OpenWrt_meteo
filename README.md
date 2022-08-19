# OpenWrt_meteo
OpenWrt + PL2303 USB UART + DS18B20

"*.sh" files put in \usr, make executable (permissions 0755)
The contents of the "root" file - add to the existing one in \etc\crontabs

"narodmon_send.sh" requires a configured ssmtp. to the variable EMAIL_TO in this script - write the email address to which you want to send errors.

Temperature readings, incoming and outgoing traffic are written to /var/log/narodmon1 every 5 minutes. sent to the site every 10 minutes, if the sending fails, a second attempt is made after 130 seconds.
Errors are written to /var/log/narodmon_error.
If the size of the narodmon1 file exceeds 4kb, it is renamed by adding the current date and time to the end of the name, and the data is collected into an empty file narodmon1.
