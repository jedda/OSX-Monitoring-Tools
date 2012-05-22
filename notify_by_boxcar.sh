#!/bin/bash

#	Notify by Boxcar
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 21 May 2012
#	Initial release.

# This script pushes a Boxcar notification to your account, based on the passed arguments.
#
# Takes the following REQUIRED arguments:
#
# 	-e		Your Boxcar registered email address.
# 	-h		The affected host.
# 	-m		The notification text.

# IMPORTANT
# You will need to subscribe to the "Monitoring" generic provider with this command before this will work (sub. in your boxcar account):
# curl -d "email=your-boxcar-registered-email@example.com" http://boxcar.io/devices/providers/MH0S7xOFSwVLNvNhTpiC/notifications/subscribe

while getopts "e:h:m:" optionName; do
case "$optionName" in
e) boxcarEmail=( "$OPTARG" );;
h) host=( "$OPTARG" );;
m) message=( "$OPTARG" );;
esac
done

curl --ssl --data-urlencode "email=$boxcarEmail" \
--data-urlencode "&notification[from_screen_name]=$host" \
--data-urlencode "&notification[icon_url]=http://jedda.me/assets/BoxcarMonitoringIcon.png" \
--data-urlencode "&notification[message]=$message" \
https://boxcar.io/devices/providers/MH0S7xOFSwVLNvNhTpiC/notifications

exit 0