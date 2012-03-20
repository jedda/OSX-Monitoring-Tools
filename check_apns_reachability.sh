#!/bin/bash

#	Check APNS Reachability
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 20 Mar 2012
#	Initial release.

#	This script checks the reachability of Apple's APNS servers. This can be very useful on remote Profile Manager
#	or Lion Server collaboration installs where you may not be the only one in control of the firewall.

#	Takes no arguments, as it simply looks for a connection.

# check port 2195
status="$(openssl s_client -connect gateway.sandbox.push.apple.com:2195)"; sleep 3;
if ! echo $status | grep -q 'CONNECTED'; then
		printf "CRITICAL - gateway.push.apple.com:2195 not responding"
		exit 2
fi

# check port 2196
status="$(openssl s_client -connect gateway.sandbox.push.apple.com:2196)"; sleep 3;
if ! echo $status | grep -q 'CONNECTED'; then
		printf "CRITICAL - gateway.push.apple.com:2196 not responding"
		exit 2
fi

# we are all good!
printf "OK - APNS ports at gateway.push.apple.com are reachable"
exit 0