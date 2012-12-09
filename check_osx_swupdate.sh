#!/bin/bash

#	Check OS X Software Update Server
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 03 Dec 2012
#	Initial release.

#	Script that uses serveradmin to check that the OS X Software Update service is listed as running.
#	If all is OK, it returns performance data for the number of mirrored and enabled packages, as well as the size of the update store.
#	Can also ensure that updates are auto syncing with Apple, and that the latest check was OK.

#	Optional Flags:
#	-a		Tells the script to ensure that automatic mirroring of updates is on, and that the last check succeeded. If your setup is manual, don't use this.

#	Example:
#	./check_osx_swupdate.sh -a 

#	Performance Data - this script returns the followng Nagios performance data:
#	mirroredPkgs -			Number of packages mirrored by your Software Update Server.
#	enabledPkgs -			Number of packages currently enabled by your Software Update Server.
#	sizeOfUpdates -			Size of your specified updates directory in Kilobytes.

#	Compatibility - this script has been tested on and functions on the following stock OSes:
#	10.6 Server
#	10.7 Server
#	10.8 Server

if [[ $EUID -ne 0 ]]; then
   printf "ERROR - This script must be run as root.\n"
   exit 1
fi

# check that the swupdate service is running
swupdateStatus=`serveradmin fullstatus swupdate | grep 'swupdate:state' | sed -E 's/swupdate:state.+"(.+)"/\1/'`
if [ "$swupdateStatus" != "RUNNING" ]; then
	printf "CRITICAL - Software Update service is not running!\n"
    exit 2
fi

# grab our performance data
numOfMirroredPkg=`serveradmin fullstatus swupdate | grep 'swupdate:numOfMirroredPkg ' | grep -E -o "[0-9]+$"`
numOfEnabledPkg=`serveradmin fullstatus swupdate | grep 'swupdate:numOfEnabledPkg ' | grep -E -o "[0-9]+$"`
updatesDocRoot=`serveradmin fullstatus swupdate | grep 'swupdate:updatesDocRoot' | sed -E 's/swupdate:updatesDocRoot.+"(.+)"/\1/'`
sizeOfUpdatesDocRoot=`du -sk "$updatesDocRoot" | grep -E -o "[0-9]+"`

# see if we need to check auto mirror status
if [ "$1" == "-a" ]; then
	
	autoMirrorToggle=`serveradmin fullstatus swupdate | grep 'swupdate:autoMirror ' | grep -E -o "[a-z]+$"`
	if [ "$autoMirrorToggle" != "yes" ]; then
		printf "WARNING - Auto mirroring of packages is off! | mirroredPkgs=$numOfMirroredPkg; enabledPkgs=$numOfEnabledPkg; sizeOfUpdates=$sizeOfUpdatesDocRoot;\n"
		exit 1
	fi
	
	autoMirrorCheckError=`serveradmin fullstatus swupdate | grep 'swupdate:checkError ' | grep -E -o "[a-z]+$"`
	if [ "$autoMirrorCheckError" != "no" ]; then
		printf "WARNING - Auto mirroring of packages encountered an error on last check! | mirroredPkgs=$numOfMirroredPkg; enabledPkgs=$numOfEnabledPkg; sizeOfUpdates=$sizeOfUpdatesDocRoot;\n"
		exit 1
	fi
	
fi

# lastly, make sure that we can connect to the service port
swupdateServicePort=`serveradmin settings swupdate | grep 'swupdate:portToUse' | grep -E -o "[0-9]+$"`
curl -silent localhost:$swupdateServicePort > /dev/null
if [ $? == 7 ]; then
    printf "CRITICAL - Could not connect to the Software Update service port ($swupdateServicePort). | mirroredPkgs=$numOfMirroredPkg; enabledPkgs=$numOfEnabledPkg; sizeOfUpdates=$sizeOfUpdatesDocRoot;\n"
    exit 2
fi

printf "OK - Software Update service appears to be running OK. | mirroredPkgs=$numOfMirroredPkg; enabledPkgs=$numOfEnabledPkg; sizeOfUpdates=$sizeOfUpdatesDocRoot;\n"
exit 0