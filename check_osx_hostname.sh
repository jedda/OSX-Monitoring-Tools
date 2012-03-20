#!/bin/bash

#	Check Mac OS X Server Hostname
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 20 Mar 2012
#	Initial release.

#	Simple script that makes sure the infamous changeip -checkhostname command returns a happy status.
#	Takes no arguments, as it simply looks for the happy text.

if echo `sudo changeip -checkhostname` | grep -q "The names match."
	then
  		printf "OK - Hostname matched.\n"
  		exit 0
	else
  		printf "CRITICAL - Hostname check failed!\n"
		exit 2
fi
