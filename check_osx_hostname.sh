#!/bin/bash

#	Check Mac OS X Server Hostname
#	by Jedda Wignall
#	http://jedda.me

#	v1.1 - 12 Aug 2013
#	Significant re-work. Now also does a forward and reverse lookup to ensure server DNS is healthy.

#	v1.0 - 20 Mar 2012
#	Initial release.

#	Simple script that makes sure the infamous changeip -checkhostname command returns a happy status.
#	It then does a forward and reverse lookup of the returned hostname and IP adress to make sure that DNS is healthy.

checkHostname=`sudo /Applications/Server.app/Contents/ServerRoot/usr/sbin/changeip -checkhostname`
regex="s.+=.([0-9].+)..Cu.+=.([a-z0-9.-]+).D"

if echo $checkHostname | grep -q "The names match."; then
	[[ $checkHostname =~ $regex ]]
	if [ "${BASH_REMATCH[0]}" != "" ]; then
		forward=`dig ${BASH_REMATCH[2]} +short`
		reverse=`dig -x ${BASH_REMATCH[1]} +short`
		if [ "$forward" != "${BASH_REMATCH[1]}" ]; then
			printf "CRITICAL - DNS lookup of ${BASH_REMATCH[2]} yielded $forward. We expected ${BASH_REMATCH[1]}!\n"
	  		exit 2
		elif [ "$reverse" != "${BASH_REMATCH[2]}." ]; then
			printf "CRITICAL - Reverse DNS lookup of ${BASH_REMATCH[1]} yielded $reverse. We expected ${BASH_REMATCH[2]}.!\n"
	  		exit 2
		fi
	else
		printf "CRITICAL - Could not read hostname or IP! Run 'sudo changeip -checkhostname' on server!\n"
  		exit 2
	fi
  		printf "OK - Hostname is ${BASH_REMATCH[2]}. Forward and reverse lookups matched expected values.\n"
  		exit 0
else
  	printf "CRITICAL - Hostname check returned non matching names!\n"
	exit 2
fi
