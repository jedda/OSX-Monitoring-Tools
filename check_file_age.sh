#!/bin/bash

#	Check file age
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 21 Feb 2012
#	Initial release.

#	Script that checks the last modification date of a file, and warns if a certain threshold of minutes has passed since last modification.
#	Takes two arguments (file path, minutes):
#	./check_file_age.sh /test.txt 3600

# 	There are plenty of file age scripts on nagios exchange, but I wanted a portable bash version
#	(not reliant on working perl or python installs) that could report on single files.check

# 	We use this on heaps of our monitored Macs to check a range of things:
#
#	Ensure currency of pgsql dumps on Lion Server
#	./check_file_age.sh /Library/Server/PostgreSQL/Backups/dumpall.sql 3600
#
#	Check currency of locally stored CrashPlan backups
#	./check_file_age.sh /Volumes/CP/484907427172245292/cpbf0000000000000000000/484907427172245292 1440
#	Check currency of locally stored CrashPlan backups


if ! [ -f "$1" ];
then
	printf "CRITICAL - $1 does not exist!\n"
	exit 2
fi

if echo `find "$1" -mmin +$2` | grep -q "$1"; then
	printf "WARNING - $1 has NOT been modified within $2 minutes\n"
	exit 1
else
	printf "OK - $1 was modified within $2 minutes\n"
	exit 0
fi