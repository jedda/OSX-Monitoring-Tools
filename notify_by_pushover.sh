#!/bin/bash

#	Notify by Pushover
#	by Jedda Wignall
#	http://jedda.me

#	v1.2.1 - 17 Mar 2013
#	Now parses title and message for sound processing.

#	v1.2 - 18 Dec 2012
#	Added parsing of title for specific warning, critical, and OK sounds.

#	v1.1 - 02 Dec 2012
#	Added notification sounds.

#	v1.0 - 21 Aug 2012
#	Initial release.

#	This script sends a Pushover (http://pushover.net/) notification to your account. I use it in a Nagios setup
#	to send network monitoring notifications, but it could be used or adapted for nearly any scenario.

#	IMPORTANT
#	You will need to create a Pushover 'Application' for this script in your account, and use the provided API key
#	as an argument. You can register an app once logged into Pushover at the follwing link:
#	https://pushover.net/apps/build

# 	Takes the following REQUIRED arguments:

# 	-u		Your Pushover user key.
# 	-a		Your Pushover application key.
# 	-t		The notification title.
# 	-m		The notification body.

# 	and the following OPTIONAL arguments:

# 	-p		Notification priority. Set to 1 to ignore quiet times.
# 	-s		Notification sound. You must use one of the parameters listed at https://pushover.net/api#sounds.
#	-w		Warning notification sound. The script will look for the text 'WARNING' in the notification title, and use this sound if found.
#	-c		Critical notification sound. The script will look for the text 'CRITICAL' in the notification title, and use this sound if found.
#	-o		OK notification sound. The script will look for the text 'OK' in the notification title, and use this sound if found.

# 	Example:
#	./notify_by_pushover.sh -u r5j7mjYjd -a noZ9KuR5T -s 'spacealarm' -t "server.pretendco.com" -m "DISK WARNING - free space: /dev/disk0s2 4784 MB"


while getopts "u:a:t:m:p:s:w:c:o:" optionName; do
case "$optionName" in
u) userKey=( "$OPTARG" );;
a) appToken=( "$OPTARG" );;
t) title=( "$OPTARG" );;
m) message=( "$OPTARG" );;
p) priority=( "$OPTARG" );;
s) sound=( "$OPTARG" );;
w) warnSound=( "$OPTARG" );;
c) critSound=( "$OPTARG" );;
o) okSound=( "$OPTARG" );;

esac
done

if [ "$priority" != "" ]; then
	priorityString="priority=$priority"
else
	priorityString="priority=0"
fi

if echo $title $message | grep -q 'WARNING' && [ "$warnSound" != "" ] ;then
    sound=$warnSound
elif echo $title $message | grep -q 'CRITICAL' && [ "$critSound" != "" ] ;then
	sound=$critSound
elif echo $title $message | grep -q 'OK' && [ "$okSound" != "" ] ;then
	sound=$okSound
fi

curl -F "token=$appToken" \
-F "user=$userKey" \
-F "title=$title" \
-F "message=$message" \
-F "sound=$sound" \
-F "$priorityString" \
https://api.pushover.net/1/messages

exit 0