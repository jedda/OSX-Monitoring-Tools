#!/bin/bash

#	Check Daylite Postgres
#	by Dan Barrett
#	http://yesdevnull.net

#	v1.0 - 9 Aug 2013
#	Initial release.

#	Checks to make sure the user _dayliteserver has spawned at least one Postgres process

#	Example:
#	./check_daylite_postgres.sh

result=`ps aux -o tty | grep _dayliteserver`
if echo $result | grep -q postgres; then
	printf "OK - Daylite has spawned at least one Postgres instance.\n"
	exit 0
else
	printf "CRITICAL - Daylite has no Postgres instances running!.\n"
	exit 2
fi