#!/bin/bash

#	Check Open Directory Status
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 30 Nov 2012
#	Initial release.

#	Script that uses status elements from serveradmin to report the status of LDAP, PasswordServer, and Kerberos
#	as Mac OS X Server understands them. As this script uses the serveradmin tool, it requires root priveleges.

#	The script will run with no arguments, and will check to ensure serveradmin sees the three components of
#	Open Directory as RUNNING. You should however use the optional arguments below to ensure your config is sound.

#	Optional Arguments:
#	-t		Expected server type to check against. The two main options here are 'master', and 'replica'.
#	-s		Expected LDAP search base to check against.
#	-r		Expected Kerberos realm to check against.

#	Example:
#	./check_od_status.sh -t 'master' -s 'dc=odm,dc=pretendco,dc=com'-r 'ODM.PRETENDCO.COM'

#	We use this on our client's monitored servers to ensure that no changes have been made to OD configurations, and that
#	those configs have come up clean across reboots, ect.

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

dirservStatus=`serveradmin fullstatus dirserv` 

# check kerberos kdc status
kdcStatusString=`echo $dirservStatus | grep -Po 'dirserv:kdcStatus.*?\K(?<=").*?(?=")'`
if [ "$kdcStatusString" != "RUNNING" ]; then
	printf "CRITICAL - Kerberos KDC does not appear to be running!\n"
	exit 2
fi

# check password server status
passStatusString=`echo $dirservStatus | grep -Po 'dirserv:passwordServiceState.*?\K(?<=").*?(?=")'`
if [ "$passStatusString" != "RUNNING" ]; then
	printf "CRITICAL - Password Server does not appear to be running!\n"
	exit 2
fi

# check ldap status
passStatusString=`echo $dirservStatus | grep -Po 'dirserv:ldapdState.*?\K(?<=").*?(?=")'`
if [ "$passStatusString" != "RUNNING" ]; then
	printf "CRITICAL - LDAP Server does not appear to be running!\n"
	exit 2
fi

serverTypeString=`echo $dirservStatus | grep -Po 'dirserv:LDAPServerType.*?\K(?<=").*?(?=")'`
if [ "$expectedServerType" != "" ]; then
	# we are going to check against our expected server type
	if [ "$serverTypeString" != "$expectedServerType" ]; then
		printf "CRITICAL - OD server type does not match expected! We expected $expectedServerType, but reported type was $serverTypeString.\n"
		exit 2
	fi
fi

if [ "$expectedSearchBase" != "" ]; then
	# we are going to check against our expected search base
	searchBaseString=`echo $dirservStatus | grep -Po 'dirserv:ldapSearchBase.*?\K(?<=").*?(?=")'`
	if [ "$searchBaseString" != "$expectedSearchBase" ]; then
		printf "CRITICAL - LDAP search base does not match expected! We expected $expectedSearchBase, but reported type was $searchBaseString.\n"
		exit 2
	fi
fi

if [ "$expectedKerberosRealm" != "" ]; then
	# we are going to check against our expected kerberos realm
	kerberosRealmString=`echo $dirservStatus | grep -Po 'dirserv:kdcHostedRealm.*?\K(?<=").*?(?=")'`
	if [ "$kerberosRealmString" != "$expectedKerberosRealm" ]; then
		printf "CRITICAL - Kerberos realm does not match expected! We expected $expectedKerberosRealm, but reported type was $kerberosRealmString.\n"
		exit 2
	fi
fi

printf "OK - Server reports that the components of this OD $serverTypeString are running OK.\n"
exit 0