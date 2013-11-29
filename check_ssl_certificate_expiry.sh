#!/bin/bash

#	Check SSL Certificate Expiry
#	by Dan Barrett
#	http://yesdevnull.net

#	v1.0 - 29 November 2013
#	Initial release.

#	Checks the specified certificate and warns you if the certificate is going
#	to expire soon, or if it has already expired, or if it isn't valid yet.

#	Arguments:
#	-h   Host address
#	-p   Port of SSL service
#	-e   Expiry in days

#	Example:
#	./check_ssl_certificate.expiry -h apple.com -p 443 -e 7

# Set up our blank variables
host=""
port=""
expiryInDays=""

while getopts "h:p:e:" opt
	do
		case $opt in
			h ) host=$OPTARG;;
			p ) port=$OPTARG;;
			e ) expiryInDays=$OPTARG;;
		esac
done

currentDateInEpoch=`date +%s`
expiryDays=$(( $expiryInDays * 86400 ))

# Quick function to tidy up output results in days
numberOfDays() {
	dayDiff=`printf "%.0f" $( echo "scale=0; $1 / 60 / 60 / 24" | bc -l )`
	dayDiff=`echo $dayDiff | sed 's/-//g'`

	dayName="days"

	if [ "$dayDiff" -eq "1" ]
	then
		dayName="day"
	fi

	echo "$dayDiff $dayName"
}

beforeExpiry=`echo "QUIT" | openssl s_client -connect $host:$port 2>/dev/null | openssl x509 -noout -startdate 2>/dev/null`
afterExpiry=`echo "QUIT" | openssl s_client -connect $host:$port 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null`

# If the stdout of the date results is null, throw a critical(2)
if [ -z "$beforeExpiry" ] || [ -z "$afterExpiry" ]
then
	printf "CRITICAL - Unable to read certificate.\n"
	exit 2
fi

notBefore=`echo $beforeExpiry | grep -C 0 "notBefore" | grep -E -o "[A-Za-z]{3,4} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2} [0-9]{3,4} [A-Z]{2,3}"`
notBeforeExpiry=`date -j -f "%b %d %H:%M:%S %Y %Z" "$notBefore" "+%s"`

diff=$(( $currentDateInEpoch - $notBeforeExpiry ))

# Is certificate not valid until the future?  If so, throw a critical(2)
if [ "$diff" -lt "0" ]
then
	printf "CRITICAL - Certificate is not valid for $( numberOfDays $diff )!\n"
	exit 2
fi

notAfter=`echo $afterExpiry | grep -C 0 "notAfter" | grep -E -o "[A-Za-z]{3,4} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2} [0-9]{3,4} [A-Z]{2,3}"`
notAfterExpiry=`date -j -f "%b %d %H:%M:%S %Y %Z" "$notAfter" "+%s"`

diff=$(( $notAfterExpiry - $currentDateInEpoch ))

# If the differential is less than 0, the certificate has already expired, throw a critical(2)
if [ "$diff" -lt "0" ]
then
	printf "CRITICAL - Certificate expired $( numberOfDays $diff ) ago!\n"
	exit 2
fi

# If the differential is less than the expiry days, throw a warning(1)
if [ "$diff" -lt "$expiryDays" ]
then
	printf "WARNING - Certificate will expire in less than $( numberOfDays $diff ).\n"
	exit 1
fi

# All OK(0)
printf "OK - Certificate expires in $( numberOfDays $diff ).\n"
exit 0