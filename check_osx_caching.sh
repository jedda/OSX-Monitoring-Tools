#!/bin/bash

#	Check OS X Caching Server
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 17 Dec 2012
#	Initial release.

#	Script that uses serveradmin to check that the OS X Caching service is listed as running.
#	If all is OK, it returns performance data for the size and limits of cached content, number of cached packages and
#	bytes requested by and returned from the service.

#	Example:
#	./check_osx_caching.sh

#	Performance Data - this script returns the followng Nagios performance data:
#	reservedSpace -		Space reserved by the caching service for cache use.
#	cacheUsed -			Space currently used by all cached content.
#	cacheFree -			Space available for new cached content.
#	cacheLimit -		User defined limit for cache in Server.app. If unlimited, free space on the selected volume.
#	bytesRequested -	Bytes requested FROM APPLE for content. (Downloads from Apple's servers).
#	bytesReturned -		Bytes returned TO CLIENTS for content. (Cached content, as well as real-time downloads from Apple's servers).
#	numberOfPkgs -		Number of packages currently cached by the service.

#	Compatibility - this script has been tested on and functions on the following stock OSes:
#	10.8.2+ Server with Server.app 2.2+

if [[ $EUID -ne 0 ]]; then
   printf "ERROR - This script must be run as root.\n"
   exit 1
fi

# check that the caching service is running
cachingStatus=`serveradmin fullstatus caching | grep 'caching:state' | sed -E 's/caching:state.+"(.+)"/\1/'`
if [ "$cachingStatus" != "RUNNING" ]; then
	printf "CRITICAL - Caching service is not running!\n"
    exit 2
fi

# check that the caching service has registered with Apple
cachingRegistrationStatus=`serveradmin fullstatus caching | grep 'caching:RegistrationStatus ' | grep -E -o "[0-9]+$"`
if [ "$cachingRegistrationStatus" != "1" ]; then
	printf "CRITICAL - Caching service has not yet registered with Apple!\n"
    exit 2
fi


# check that the caching service is active, and that has fully started up.
cachingActive=`serveradmin fullstatus caching | grep 'caching:Active ' | grep -E -o "[a-z]+$"`
cachingStartupStatus=`serveradmin fullstatus caching | grep 'caching:StartupStatus' | sed -E 's/caching:StartupStatus.+"(.+)"/\1/'`
if [ "$cachingActive" != "yes" ] || [ "$cachingStartupStatus" != "OK" ]; then
	printf "WARNING - Caching service is running, but has not fully started up.\n"
    exit 1
fi

# check that the cache itself reports as OK
cachingStatus=`serveradmin fullstatus caching | grep 'caching:CacheStatus' | sed -E 's/caching:CacheStatus.+"(.+)"/\1/'`
if [ "$cachingStatus" != "OK" ]; then
	printf "WARNING - Caching service reported a problem with it's data cache.\n"
    exit 1
fi

# grab our performance data
reservedSpace=`serveradmin settings caching | grep 'caching:ReservedVolumeSpace ' | grep -E -o "[0-9]+$"`
cacheUsed=`serveradmin fullstatus caching | grep 'caching:CacheUsed ' | grep -E -o "[0-9]+$"`
cacheFree=`serveradmin fullstatus caching | grep 'caching:CacheFree ' | grep -E -o "[0-9]+$"`
cacheLimit=`serveradmin fullstatus caching | grep 'caching:CacheLimit ' | grep -E -o "[0-9]+$"`
bytesRequested=`serveradmin fullstatus caching | grep 'caching:TotalBytesRequested' | grep -E -o "[0-9]+$"`
bytesReturned=`serveradmin fullstatus caching | grep 'caching:TotalBytesReturned' | grep -E -o "[0-9]+$"`
databasePath="`serveradmin settings caching | grep 'caching:DataPath' | sed -E 's/caching:DataPath.+"(.+)"/\1/'`/AssetInfo.db"
numberOfPkgs=`sqlite3 $databasePath 'SELECT count(*) from ZASSET;'`

# lastly, make sure that we can connect to the service port
cachingServicePort=`serveradmin fullstatus caching | grep 'caching:Port' | grep -E -o "[0-9]+$"`
curl -silent localhost:$cachingServicePort > /dev/null
if [ $? == 7 ]; then
    printf "CRITICAL - Could not connect to the Caching service port ($swupdateServicePort).\n"
    exit 2
fi

printf "OK - Caching service appears to be running OK. | reservedSpace=$reservedSpace; cacheUsed=$cacheUsed; cacheFree=$cacheFree; cacheLimit=$cacheLimit; bytesRequested=$bytesRequested; bytesReturned=$bytesReturned; numberOfPkgs=$numberOfPkgs;\n"
exit 0