#!/bin/bash

#	Check APC SmartUPS SMT 750 Battery & Voltage (check_apc_smt750_battery.sh)
#	by Dan Barrett
#	http://yesdevnull.net

#	v1.0 - 20 August 2013
#	Initial Release

#	Requirements:
#	Apcupsd to be stored in the same directory (http://www.apcupsd.com/)

#	Arguments:
#	-w   Warning threshold for battery charge
#	-c   Critical threshold for battery charge

#	Example:
#	./check_apc_smt750_battery.sh -w 80 -c 20

warnThresh=""
critThresh=""

while getopts "w:c:" opt
	do
		case $opt in
			w ) warnThresh=$OPTARG;;
			c ) critThresh=$OPTARG;;
		esac
done

if [ "$warnThresh" == "" ]
then
	printf "ERROR - You must provide a warning threshold with -w!\n"
	exit 2
fi

if [ "$critThresh" == "" ]
then
	printf "ERROR - You must provide a critical threshold with -c!\n"
	exit 1
fi

battCharge=`/opt/local/libexec/nagios/check_apcupsd.sh -w $warnThresh -c $critThresh bcharge | grep -E -o "[0-9.]+"`
battVoltage=`/opt/local/libexec/nagios/check_apcupsd.sh battv | grep -E -o "[0-9.]+"`

# Do BC math because battCharge is returned as a float
critMath=`echo $battCharge '<=' $critThresh | bc -l`
if [ $critMath -eq 1 ]
then
	printf "CRITICAL - battery charge is $battCharge%%, which is below $critThresh%% | battCharge=$battCharge; battVoltage=$battVoltage; warnThresh=$warnThresh; critThresh=$critThresh;\n"
	exit 2
fi

# Do BC math because battCharge is returned as a float
warnMath=`echo $battCharge '<=' $warnThresh | bc -l`
if [ $warnMath -eq 1 ]
then
	printf "WARNING - battery charge is $battCharge%%, which is below $warnThresh%% | battCharge=$battCharge; battVoltage=$battVoltage; warnThresh=$warnThresh; critThresh=$critThresh;\n"
	exit 1
fi

printf "OK - battery charge is at $battCharge%% | battCharge=$battCharge; battVoltage=$battVoltage; warnThresh=$warnThresh; critThresh=$critThresh;\n"
exit 0