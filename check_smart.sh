#!/bin/bash

#	Check S.M.A.R.T. (check_smart.sh)
#	by Dan Barrett
#	http://yesdevnull.net

#	v1.0 - 9 Aug 2013
#	Initial release.

#	Read S.M.A.R.T. data from the specified disk using smartmontools
#	(http://sourceforge.net/apps/trac/smartmontools/wiki)

#	Arguments:
#	-d	Drive BSD name (disk0/disk1 etc)
#	-g	Graph item(s)

#	Example:
#	./check_smart.sh -d disk0 -g "badSectors tempCelcius"

#	Performance Data
#	* badSectors		Number of bad sectors on disk
#	* reallocSectors	Number of re-allocated sectors on disk
#	* powerOnHours		Number of hours the disk has been powered on for
#	* tempCelcius		Temperature in celcius of the disk (internal)

disk=""
graphs=""
graphString=""

badSectors=0
reallocSectors=0

# Get the flags!
while getopts "d:g:" opt
	do
		case $opt in
			d ) disk=$OPTARG;;
			g ) graphs=$OPTARG;;
		esac
done

# enable SMART on the drive if it is not already
smartoncmd=`/opt/local/libexec/nagios/smartctl --smart=on --saveauto=on $disk`

resultString=`/opt/local/libexec/nagios/smartctl -H $disk`

if echo $graphs | grep -q -E "[A-Za-z ]+"
then
	graphString="|"
fi

# Did user want badSectors graph?
if echo $graphs | grep -q "badSectors"
then
	badSectors=`/opt/local/libexec/nagios/smartctl -a $disk | grep -C 0 'Reallocated_Sector_Ct' | grep -E -o "[0-9]+" | tail -1 `
	graphString="$graphString badSectors=$badSectors;"
fi

# Did user want reallocSectors graph?
if echo $graphs | grep -q "reallocSectors"
then
	reallocSectors=`/opt/local/libexec/nagios/smartctl -a $disk | grep -C 0 'Reallocated_Event_Count' | grep -E -o "[0-9]+" | tail -1`
	graphString="$graphString reallocSectors=$reallocSectors;"
fi

# Did user want powerOnHours graph?
if echo $graphs | grep -q "powerOnHours"
then
	powerOnHours=`/opt/local/libexec/nagios/smartctl -a $disk | grep -C 0 'Power_On_Hours' | grep -E -o "[0-9]+" | tail -1`
	graphString="$graphString powerOnHours=$powerOnHours;"
fi

# Did user want tempCelcius graph?
if echo $graphs | grep -q "tempCelcius"
then
	internalTemp=`/opt/local/libexec/nagios/smartctl -a $disk | grep -C 0 'Temperature_Celsius' | grep -E -o "[0-9]+" | tail -1`
	graphString="$graphString tempCelcius=$internalTemp;"
fi

if echo $resultString | grep -q "PASSED"
then
  	printf "OK - All S.M.A.R.T. attributes passed $graphString\n"
  	exit 0
else
	# Get the first line that is FAILING_NOW
	failString=`echo $resultString | grep -C 0 'FAILING_NOW'`
	# Now we make a human readable error message
	if echo $failString | grep -q "Reallocated_Sector_Ct\|Reallocated_Event_Count"
	then
		printf "CRITICAL - Drive has bad sectors! $graphString\n"
		exit 2
	elif echo $failString | grep -q "Command_Timeout" 
	then
		printf "CRITICAL - Drive is having constant timeout issues, check any power sources! $graphString\n"
		exit 2
	elif echo $failString | grep -q "Temperature_Celsius"
	then
		printf "CRITICAL - Drive is exposed to extreme temperatures! $graphString\n"
		exit 2
	else
		printf "WARNING - Drive has failing S.M.A.R.T. attributes! $graphString\n"
		exit 1
	fi
fi