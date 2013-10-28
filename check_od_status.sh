#!/bin/bash

#	Check Open Directory Status
#	by Jedda Wignall
#	http://jedda.me

#	v1.2 - 7 Dec 2012
#	Added performance data for slapd connections.
#
#	v1.1 - 2 Dec 2012
#	Re-release to fix Mountain Lion issues. Script now runs on 10.8, and will 'fall back' to further checks on 10.7 and earlier.
#
#	v1.0 - 30 Nov 2012
#	Initial release.

#	Script that uses status elements from serveradmin to report the status of LDAP, PasswordServer, and Kerberos
#	as Mac OS X Server understands them. As this script uses the serveradmin tool, it requires root priveleges.

#	The script will run with no arguments, and will check to ensure serveradmin sees Open Directory as RUNNING.
#	On 10.7 and earlier, it will also check individual OD components. In a production environment, I recommend
#	usage of the optional arguments below to ensure your config remains sound and unchanged.

#	Optional Arguments:
#	-t		Expected server type to check against. The two main options here are 'master', and 'replica'.
#	-s		Expected LDAP search base to check against.
#	-r		Expected Kerberos realm to check against.

#	Example:
#	./check_od_status.sh -t 'master' -s 'dc=odm,dc=pretendco,dc=com'-r 'ODM.PRETENDCO.COM'

#	Performance Data - this script returns the followng Nagios performance data:
#	slapdConn -				Number of tcp connections to slapd LDAP daemon.

#	We use this on our client's monitored servers to ensure that no changes have been made to OD configurations, and that
#	those configs have come up clean across reboots, ect.

#	Compatibility - this script has been tested on and functions on the following stock OSes:
#	10.5 Server
#	10.6 Server
#	10.7 Server
#	10.8 Server
#	10.9 Server

if [[ $EUID -ne 0 ]]; then
   printf "ERROR - This script must be run as root.\n"
   exit 1
fi

expectedServerType=""
expectedSearchBase=""
expectedKerberosRealm=""

while getopts "t:s:r:" optionName; do
case "$optionName" in
t) expectedServerType=( "$OPTARG" );;
s) expectedSearchBase=( "$OPTARG" );;
r) expectedKerberosRealm=( "$OPTARG" );;
esac
done

# check od status
odStatusString=`serveradmin fullstatus dirserv | grep 'dirserv:state' | sed -E 's/dirserv:state.+"(.+)"/\1/'`
if [ "$odStatusString" != "RUNNING" ]; then
	printf "CRITICAL - Open Directory does not appear to be running!\n"
	exit 2
fi

if sw_vers | grep -q '10.5' || sw_vers | grep -q '10.6' || sw_vers | grep -q '10.7'; then
	
	# we can get specific statuses on od components in 10.5-7
	
	# check kerberos kdc status
	kdcStatusString=`serveradmin fullstatus dirserv | grep 'dirserv:kdcStatus' | sed -E 's/dirserv:kdcStatus.+"(.+)"/\1/'`
	if [ "$kdcStatusString" != "RUNNING" ]; then
		printf "CRITICAL - Kerberos KDC does not appear to be running!\n"
		exit 2
	fi

	# check password server status
	passStatusString=`serveradmin fullstatus dirserv | grep 'dirserv:passwordServiceState' | sed -E 's/dirserv:passwordServiceState.+"(.+)"/\1/'`
	if [ "$passStatusString" != "RUNNING" ]; then
		printf "CRITICAL - Password Server does not appear to be running!\n"
		exit 2
	fi

	# check ldap status
	ldapdStatusString=`serveradmin fullstatus dirserv | grep 'dirserv:ldapdState' | sed -E 's/dirserv:ldapdState.+"(.+)"/\1/'`
	if [ "$ldapdStatusString" != "RUNNING" ]; then
		printf "CRITICAL - LDAP Server does not appear to be running!\n"
		exit 2
	fi

fi

# check how many tcp connections slapd currently has
slapdConnections=`sudo lsof -i tcp:389 | grep slapd | wc -l | grep -E -o "[0-9]+"`

serverTypeString=`serveradmin fullstatus dirserv | grep 'dirserv:LDAPServerType' | sed -E 's/dirserv:LDAPServerType.+"(.+)"/\1/'`
if [ "$expectedServerType" != "" ]; then
	# we are going to check against our expected server type
	if [ "$serverTypeString" != "$expectedServerType" ]; then
		printf "CRITICAL - OD server type does not match expected! We expected $expectedServerType, but reported type was $serverTypeString. | slapdConn=$slapdConnections;\n"
		exit 2
	fi
fi

if [ "$expectedSearchBase" != "" ]; then
	# we are going to check against our expected search base
	searchBaseString=`serveradmin fullstatus dirserv | grep 'dirserv:ldapSearchBase' | sed -E 's/dirserv:ldapSearchBase.+"(.+)"/\1/'`
	if [ "$searchBaseString" != "$expectedSearchBase" ]; then
		printf "CRITICAL - LDAP search base does not match expected! We expected $expectedSearchBase, but reported type was $searchBaseString. | slapdConn=$slapdConnections;\n"
		exit 2
	fi
fi

if [ "$expectedKerberosRealm" != "" ]; then
	# we are going to check against our expected kerberos realm
	kerberosRealmString=`serveradmin fullstatus dirserv | grep 'dirserv:kdcHostedRealm' | sed -E 's/dirserv:kdcHostedRealm.+"(.+)"/\1/'`
	if [ "$kerberosRealmString" != "$expectedKerberosRealm" ]; then
		printf "CRITICAL - Kerberos realm does not match expected! We expected $expectedKerberosRealm, but reported type was $kerberosRealmString. | slapdConn=$slapdConnections;\n"
		exit 2
	fi
fi

printf "OK - Server reports that the components of this OD $serverTypeString are running OK. | slapdConn=$slapdConnections;\n"
exit 0