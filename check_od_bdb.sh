#!/bin/bash

#	Check Open Directory BDB databases
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 27 Mar 2012
#	Initial release.

#	This script verifies each of the .bdb files in /var/db/openldap/openldap-data/*.bdb and returns
#	a critical status if verification fails. You really only need to have this run once a day, or even weekly.

for db in /var/db/openldap/openldap-data/*.bdb
do
	result=`db_verify -q "$db"`
	if [ $? != 0 ]; then
		printf "CRITICAL: $db failed verification!\n"
		exit 2
	fi
done

printf "OK - All bdb databases verified\n"
exit 0