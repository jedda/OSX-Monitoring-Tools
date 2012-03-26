#!/bin/bash

#	Check Kerio Connect Statistics
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 26 Mar 2012
#	Initial release.

#	This script checks the stats.dat file in your kerio connect mailstore and lets you know if counters have passed warn/crit thresholds.
#	It returns full performance data on the requested counters, and finishes by using the Kerio Admin API to reset your statistics.
#	
#	You will need to fill in a few variables below to get this working.

#	The script takes the following arguments:
#	-n		Quoted list (space delimited) of counter names you want to query.
#	-n		Quoted list (space delimited) (same order) of warning thresholds for the counters.
#	-c		Quoted list (space delimited) (same order) of critical thresholds for the counters.
#
#	Examples:
#
#	./check_kerio_connect_stats.sh -n "mtaLargestSize" -w "4000" -c "10000"
#	returns:
#	OK | mtaLargestSize=3394;
#
#	./check_kerio_connect_stats.sh -n "mtaReceivedMessages mtaTransmittedMessages" -w "5 35" -c "25 48"
#	returns:
#	WARNING: mtaReceivedMessages is 8 | mtaReceivedMessages=8;mtaTransmittedMessages=11;

# START CONFIG SECTION
# the local path to your kerio connect mailstore. change if different
kerioStore="/usr/local/kerio/mailserver"
# put your kerio admin url, username and password below. this is used to reset your kerio stats after we are done.
kerioAdminURL="https://your.server.url:4040"
kerioAdminUser="Admin"
kerioAdminPass="*YourPassword*"
# END CONFIG SECTION

# from here below is the script - don't change variables unless you know what you are doing
function resetKerioStatistics() { 
login=`curl --cookie /tmp/tempcookies --cookie-jar /tmp/tempcookies -k -X POST -H "Content-type: application/json" \
-d '{"jsonrpc": "2.0","id": 1,"method": "Session.login","params": {"userName": "'$kerioAdminUser'","password": "'$kerioAdminPass'","application": {"name": "Statistics Reset","vendor": "jedda.me","version": "1.0.0"}}}
' -silent $kerioAdminURL'/admin/api/jsonrpc'`
token=`echo $login | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w token | awk -F '|' '{ print $3 }'`
reset=`curl --cookie /tmp/tempcookies -k -X POST -H "Content-type: application/json" -H "X-Token: $token" -d '{"jsonrpc":"2.0","id":1,"method":"Statistics.reset","params":{}}' -silent $kerioAdminURL'/admin/api/jsonrpc'`
logout=`curl --cookie /tmp/tempcookies -k -X POST -H "Content-type: application/json" -H "X-Token: $token" -d '{"jsonrpc": "2.0","id": 1, "method": "Session.logout"}' -silent $kerioAdminURL'/admin/api/jsonrpc'`
}

nameList=""
warnList=""
critList=""
performance=""
warnString=""
critString=""
i=0

while getopts "n:w:c:" optionName; do
case "$optionName" in
n) nameList=( $OPTARG );;
w) warnList=( $OPTARG );;
c) critList=( $OPTARG );;
esac
done

for counter in ${nameList[*]}
do
	match=`grep $counter $kerioStore/stats.dat | tr -d '\t' `
	value=`echo $match | awk -F '[>,<]' '{ print $3 }'`
	performance="$performance${nameList[$i]}=$value;"
	if [ $value -ge ${critList[$i]} ]; then
	critString="CRITICAL: ${nameList[$i]} is $value"
	fi
	if [ $value -ge ${warnList[$i]} ]; then
	warnString="WARNING: ${nameList[$i]} is $value"
	fi
	i=$((i+1))
done

if [ "$critString" != "" ]; then
	printf "$critString | $performance\n"
	resetKerioStatistics
	exit 2
elif [ "$warnString" != "" ]; then
	printf "$warnString | $performance\n"
	resetKerioStatistics
	exit 1
else
	printf "OK | $performance\n"
	resetKerioStatistics
	exit 0
fi


