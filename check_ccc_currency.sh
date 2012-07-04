#!/bin/bash

#	Carbon Copy Clone - Check Currency
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 2 Jul 2012
#	Initial release.

#	This script has 2 modes:
#	• Can be used as a post-clone script in Carbon Copy Cloner to mark a destination as successful
#	• Can be used as a Nagios plugin to check the time of the last successful clone to a destination

#	--- In Carbon Copy Cloner (CCC) ---
#   Simply set the script as the post-clone shell script (After copying files...) for your scheduled clone. 
#	More information can be found at my original blog post about this script (http://jedda.me/2012/07/checking-carbon-copy-cloner-nagios/)
# 	or the documentation on this feature in CCC (http://www.bombich.com/software/docs/CCC/en.lproj/scheduling/performing-actions-before-and-after-the-backup-task.html)

#	--- In Nagios ---
#	This script checks .ccc_clone_last_completed file on a volume, and reports if a clone has completed successfully within a number of minutes of the current time.
#	Takes two arguments (clone destination, warning threshold in minutes):
#	./check_ccc_currency.sh -d '/Volumes/Boot-Clone' -w 1440

destVolume=""
warnMinutes=""

while getopts "d:w:" optionName; do
case "$optionName" in
d) destVolume=("$OPTARG");;
w) warnMinutes=( $OPTARG );;
esac
done

parentProcess=`ps -ocommand= -p $PPID | awk -F/ '{print $NF}' | awk '{print $1}'`

# check to see if we are being called from CCC
if [ "$parentProcess" = "com.bombich.ccc" ]; then
	# we are being called by CCC
	echo "We are being called by CCC"
	if [ $3 -eq 0 ]; then
		echo "Clone to $2 was good!"
		# clone completed successfully
		touch "$2/.ccc_clone_last_completed"
	fi
	exit 0
else
	# we are NOT being called by CCC
	if ! [ -f "$destVolume/.ccc_clone_last_completed" ];
	then
		printf "CRITICAL - $destVolume has never been a successful clone destination!\n"
		exit 2
	fi
	if echo `find "$destVolume/.ccc_clone_last_completed" -mmin +$warnMinutes` | grep -q "$destVolume/.ccc_clone_last_completed"; then
		printf "WARNING - A clone has NOT succeeded to $destVolume in more than $warnMinutes minutes\n"
		exit 1
	else
		printf "OK - A clone to $destVolume has succeeded within the last $warnMinutes minutes\n"
		exit 0
	fi
fi