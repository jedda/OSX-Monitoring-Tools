#!/bin/bash

#	Check FreeRADIUS Server Status
#	by Dan Barrett
#	http://yesdevnull.net

#	v1.0 - 24 August 2013
#	Initial Release

#	v1.1 - 27 October 2013
#	Updated for OS X Mavericks

#	This script does a number of checks to verify that the FreeRADIUS server is running.
#	Please ensure you have a valid user account to check the full status of the server.

#	Arguments:
#	-u   Username to test authentication
#	-p   Password for the above user
#	-h   The host for the FreeRADIUS server (usually localhost)
#	-a   The port for the FreeRADIUS server (usually 1812)
#	-s   The shared secret for the IP address you're connecting from (testing123 if testing on localhost)

#	Example:
#	./check_radius.sh -u fakeuser -p fakepass -h localhost -a 1812 -s fake_shared_secret

#	Supports:
#	* OS X 10.8 Mountain Lion, Server 2.2.x
#	* OS X 10.9 Mavericks, Server 3.0

# We need to run this as root because FreeRADIUS requires it, plus we write a temp log file
if [[ $EUID -ne 0 ]]
then
	echo "ERROR - This script must be run as root."
	exit 1
fi

# Set up the basic variables
username=""
password=""
host=""
port=""
secret=""

while getopts "u:p:h:a:s:" opt
	do
		case $opt in
			u ) username=$OPTARG;;
			p ) password=$OPTARG;;
			h ) host=$OPTARG;;
			a ) port=$OPTARG;;
			s ) secret=$OPTARG;;
		esac
done

# Check to see if we're running Mavericks Server as RADIUS runs a little differently
osVersion=`sw_vers -productVersion | grep -E -o "[0-9]+\.[0-9]"`
isMavericks=`echo $osVersion '< 10.9' | bc -l`

if [ $isMavericks -eq 0 ]
then
	# 10.9+ Check
	# Quick check to see if FreeRADIUS is even running
	if [ "`ps -ef | grep radiusd`" == "" ]
	then
		echo "CRITICAL - RADIUS is not running!"
		exit 2
	fi
else
	# < 10.9 Check
	# Quick check to see if FreeRADIUS is even running
	if [ "`ps aux -o tty | grep "/usr/sbin/radius"`" == "" ]
	then
		echo "CRITICAL - RADIUS is not running!"
		exit 2
	fi
fi

# Attempt to authenticate with the FreeRADIUS server, using the credentials and details above, then send stderr to a temp log file
authAttempt=`echo "User-Name=$username,User-Password=$password,Framed-Protocol=PPP " | radclient -x -r 1 -t 2 $host:$port auth $secret 2> /tmp/radius_error`
# Assign the stderr log file to a variable
radiusStderr=$(</tmp/radius_error)

# What did authAttempt return?  Good news I hope.
if [ `echo $authAttempt | grep -o "Access-Accept"` ]
then
	# Success!
	echo "OK - RADIUS is running and accepting connections."
	exit 0
elif [ `echo $radiusStderr | grep -o "Shared"` ]
then
	echo "WARNING - RADIUS is running, but your shared secret is incorrect."
	exit 1
elif [ `echo $authAttempt | grep -o "Access-Reject"` ]
then
	echo "WARNING - RADIUS is running, but your credentials are incorrect."
	exit 1
else
	# If we get some other error, return a generic error
	echo "CRITICAL - RADIUS is running but not accepting connections!"
	exit 2
fi