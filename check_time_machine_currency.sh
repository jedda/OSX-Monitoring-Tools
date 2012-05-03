#!/bin/bash

#	Check Time Machine Currency
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 3 May 2012
#	Initial release.

#	This script checks the time machine results file on a Mac, and reports if a backup has completed within a number of minutes of the current time.
#	Takes two arguments (warning threshold in minutes, critical threshold in minutes):
#	./check_time_machine_currency.sh -w 240 -c 1440

# 	Very useful if you are monitoring client production systems, and want to ensure backups are occurring.

while getopts "d:w:c:" optionName; do
case "$optionName" in
w) warnMinutes=( $OPTARG );;
c) critMinutes=( $OPTARG );;
esac
done

lastBackupDateString=`defaults read /private/var/db/.TimeMachine.Results BACKUP_COMPLETED_DATE`

if echo $lastBackupDateString | grep -q 'does not exist'; then
	printf "CRITICAL - Time Machine has not completed a backup on this Mac!\n"
	exit 2
fi

lastBackupDate=$(date -j -f "%Y-%m-%e %H:%M:%S %z" "$lastBackupDateString" "+%s" )

diff=$(( $currentDate - $lastBackupDate))
warnSeconds=$(($warnMinutes * 60))
critSeconds=$(($critMinutes * 60))

if [ "$diff" -gt "$critSeconds" ]; then
	printf "CRITICAL - Time Machine has not backed up in more than $critMinutes minutes!\n"
	exit 2
elif [ "$diff" -gt "$warnSeconds" ]; then
	printf "WARNING - Time Machine has not backed up in more than $warnMinutes minutes!\n"
	exit 1
fi

printf "OK - A Time Machine backup has been taken within the last $warnMinutes minutes.\n"
exit 0