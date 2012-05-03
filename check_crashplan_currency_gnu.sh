#!/bin/bash

#	Check Crashplan Currency - GNU
#	by Jedda Wignall
#	http://jedda.me

#	v1.0.1 - 3 May 2012
#	Added comments and fixed broken bits.

#	v1.0 - 27 Apr 2012
#	Initial release.

#	This script checks the currency of a CrashPlan backup on Linux. There is a different version for Mac OS X due to differences between date on GNU and BSD.
#	Takes three arguments ([-d] cp.properties file in backup destination, [-w] warning threshold in minutes, [-c] critical threshold in minutes):
#	./check_crashplan_currency_gnu.sh -d /media/Backups/52352423423424243/cp.properties -w 240 -c 1440

currentDate=`date "+%s"`
cpDirectory=""
warnMinutes=""
critMinutes=""

while getopts "d:w:c:" optionName; do
case "$optionName" in
d) cpDirectory=("$OPTARG");;
w) warnMinutes=( $OPTARG );;
c) critMinutes=( $OPTARG );;
esac
done


# check to see if the cp.properties file exists
if ! [ -f "$cpDirectory" ];
then
	printf "CRITICAL - the CrashPlan backup you pointed to does not exist!\n"
	exit 2
fi

lastBackupLine=`grep -n lastCompletedBackupTimestamp "$cpDirectory"`
if [ -z "$lastBackupLine" ]; then
	printf "CRITICAL - Could not read the last backup date. Has an initial backup occurred?\n"
	exit 2
fi
lastBackupDateString=`echo $lastBackupLine | awk -F lastCompletedBackupTimestamp= '{print $NF}' | sed 's/.\{5\}$//' | sed 's/\\\//g'`
lastBackupDate=$(date -d "$lastBackupDateString" "+%s" )

diff=$(( $currentDate - $lastBackupDate))
warnSeconds=$(($warnMinutes * 60))
critSeconds=$(($critMinutes * 60))

if [ "$diff" -gt "$critSeconds" ]; then
	# this cert is has already expired! return critical status.
	printf "CRITICAL - $cpDirectory has not been backed up in more than $critMinutes minutes!\n"
	exit 2
elif [ "$diff" -gt "$warnSeconds" ]; then
	# this cert is expiring within the warning threshold. return warning status.
	printf "WARNING - $cpDirectory has not been backed up in more than $warnMinutes minutes!\n"
	exit 1
fi

printf "OK - $cpDirectory has been backed up within the last $warnMinutes minutes.\n"
exit 0