#!/bin/bash

#	Check Crashplan Currency
#	by Jedda Wignall
#	http://jedda.me


#	v1.0.1 - 3 May 2012
#	Added comments and fixed broken bits.

#	v1.0 - 27 Apr 2012
#	Initial release.

#	This script checks the currency of a CrashPlan backup on Mac OS X. There is a different version for linux due to differences between date on BSD and GNU.
#	Takes three arguments ([-d] cp.properties file in backup destination, [-w] warning threshold in minutes, [-c] critical threshold in minutes):
#	./check_crashplan_currency_gnu.sh -d /Volumes/Backups/52352423423424243/cp.properties -w 240 -c 1440

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
lastBackupDateString=`echo $lastBackupLine | awk -F lastCompletedBackupTimestamp= '{print $NF}' | sed 's/.\{5\}$//' | sed 's/%//' | sed 's/T/ /'`
lastBackupDate=$(date -j -f "%Y-%m-%eT%H\:%M\:%S" "$lastBackupDateString" "+%s" )

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
