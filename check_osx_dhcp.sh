#!/bin/bash

#	Check OS X DHCP Status
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 7 Dec 2012
#	Initial release.

#	Script that uses serveradmin to check that the OS X Server DHCP service is listed as running.
#	If all is OK, it checks that the number of active clients does not exceed a set threshold, then
#	returns performance data for the number of provided leases and number of active clients.

#	Required Arguments:
#	-w		Warning threshold for active clients. Script throws WARNING if number of active clients is greater than or equals the supplied number.
#	-c		Critical threshold for active clients. Script throws CRITICAL if number of active clients is greater than or equals the supplied number.

#	Example:
#	./check_osx_swupdate.sh -w 120 -c 180

#	Performance Data - this script returns the followng Nagios performance data:
#	providedLeases -		Number of leases provided to clients (active & non-active).
#	activeClients -			Number of clients with an active lease.

#	Compatibility - this script has been tested on and functions on the following stock OSes:
#	10.6 Server
#	10.7 Server
#	10.8 Server

if [[ $EUID -ne 0 ]]; then
   printf "ERROR - This script must be run as root.\n"
   exit 1
fi

warnThresh=""
critThresh=""

while getopts "w:c:" optionName; do
case "$optionName" in
w) warnThresh=( $OPTARG );;
c) critThresh=( $OPTARG );;
esac
done

if [ "$warnThresh" == "" ]; then
	printf "ERROR - You must provide a warning threshold with -w!\n"
	exit 3
fi

if [ "$critThresh" == "" ]; then
	printf "ERROR - You must provide a critical threshold with -c!\n"
	exit 3
fi

# check that the dhcp service is running
dhcpStatus=`serveradmin fullstatus dhcp | grep 'dhcp:state' | sed -E 's/dhcp:state.+"(.+)"/\1/'`

if [ "$dhcpStatus" != "RUNNING" ]; then
	printf "CRITICAL - DHCP service is not running!\n"
	exit 2
fi

dhcpActiveClients=`serveradmin fullstatus dhcp | grep 'dhcp:numDHCPActiveClients' | grep -E -o "[0-9]+"`
dhcpLeases=`serveradmin fullstatus dhcp | grep 'dhcp:numDHCPLeases' | grep -E -o "[0-9]+"`

if [ "$dhcpActiveClients" -ge "$critThresh" ]; then
	printf "CRITICAL - $dhcpLeases leases ($dhcpActiveClients active clients) | providedLeases=$dhcpLeases; activeClients=$dhcpActiveClients;\n"
	exit 2
elif [ "$dhcpActiveClients" -ge "$warnThresh" ]; then
	printf "WARNING - $dhcpLeases leases ($dhcpActiveClients active clients) | providedLeases=$dhcpLeases; activeClients=$dhcpActiveClients; \n"
	exit 1
fi
	
printf "DHCP OK - $dhcpLeases leases ($dhcpActiveClients active clients) | providedLeases=$dhcpLeases; activeClients=$dhcpActiveClients;\n"
exit 0