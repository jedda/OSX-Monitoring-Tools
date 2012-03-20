#!/bin/bash

#	Check Open Directory client bind
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 21 Feb 2012
#	Initial release.

#	Super simple script that id's a potential user in your directory service.
#	Takes one argument (user short name) and checks to see if id returns group information:
#	./check_od_bind.sh diradmin

# 	We use this on our OD bound mail server to ensure it is getting directory information from our master or replica.

if echo `id $1` | grep -q "uid"
	then
  		printf "OK - $1 was id'd successfully\n"
  		exit 0
	else
  		printf "CRITICAL - Could not id $1\n"
		exit 2
fi
