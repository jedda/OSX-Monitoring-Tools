#!/bin/bash

#	Check SSL Certificate Expiry
#	by Dan Barrett
#	http://yesdevnull.net

#	v1.0 - 28 November 2013
#	Initial release.

#	Checks the specified certificate and warns you if the certificate is going
#	to expire soon, or if it has already expired, or if it isn't valid yet.

#	Arguments:
#	-h   Host address
#	-p   Port o
#	-e   Expiry in days

#	Example:
#	./check_ssl_certificate.expiry -h google.com -p 443 -e 7

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
	# seconds
	dayDiff=`printf "%.0f" $( echo "scale=0; $1 / 60 / 60 / 24" | bc -l )`

	dayName="days"

	if [ "$dayDiff" -eq "1" ]
	then
		dayName="day"
	fi

	echo "$dayDiff $dayName"
}

beforeExpiryRequest=`echo "QUIT" | openssl s_client -connect $host:$port 2>/dev/null | openssl x509 -noout -startdate 1> /tmp/cert_before_output`
beforeExpiryResult=$(</tmp/cert_before_output)
afterExpiryRequest=`echo "QUIT" | openssl s_client -connect $host:$port 2>/dev/null | openssl x509 -noout -enddate 1> /tmp/cert_after_output`
afterExpiryResult=$(</tmp/cert_after_output)

notBefore=`echo $beforeExpiryResult | grep -C 0 "notBefore" | grep -E -o "[A-Za-z]{3,4} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2} [0-9]{3,4} [A-Z]{2,3}"`
notBeforeExpiry=`date -j -f "%b %d %H:%M:%S %Y %Z" "$notBefore" "+%s"`

diff=$(( $currentDateInEpoch - $notBeforeExpiry ))

if [ "$diff" -lt "0" ]
then
	printf "CRITICAL - Certificate is not valid until $( numberOfDays $diff | cut -c 2- )!\n"
	exit 2
fi

notAfter=`echo $afterExpiryResult | grep -C 0 "notAfter" | grep -E -o "[A-Za-z]{3,4} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2} [0-9]{3,4} [A-Z]{2,3}"`
notAfterExpiry=`date -j -f "%b %d %H:%M:%S %Y %Z" "$notAfter" "+%s"`

diff=$(( $notAfterExpiry - $currentDateInEpoch ))

if [ "$diff" -lt "0" ]
then
	printf "CRITICAL - Certificate expired $( numberOfDays $diff | cut -c 2- ) ago!\n"
	exit 2
fi

if [ "$diff" -lt "$expiryDays" ]
then
	printf "WARNING - Certificate will expire in less than $( numberOfDays $diff ).\n"
	exit 1
fi

printf "OK - Certificate expires in $( numberOfDays $diff ).\n"
exit 0