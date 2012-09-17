#!/bin/bash

#	Check Mac OS X Server Certificate Expiry
#	by Jedda Wignall
#	http://jedda.me

#	v1.1 - 17 Sep 2012
#	Fixed script to throw proper critical error if a cert cannot be loaded by openssl.

#	v1.0 - 20 Mar 2012
#	Initial release.

#	This script checks the expiry dates of all certificates in the /etc/certificates directory, and returns a warning if needed based on your defined number of days.
#	Takes 1 argument - the minimum number of days between today and cert expiry to throw a warning:
#
#	check_certificate_expiry.sh 7
# 	Warns if a certificate is set to expire in the next 7 days.

CERTS=/etc/certificates/*
currentDate=`date "+%s"`

for c in $CERTS
do
	fileType=`echo $c | awk -F . '{print $(NF-1)}'`
	if [ $fileType == 'cert' ]; then
		# read the dates on each certificate
		certDates=`openssl x509 -noout -in "$c" -dates 2>/dev/null`
		if [ -z "$certDates" ]; then
			# this cert could not be read.
	  		printf "CRITICAL - $c could not be loaded by openssl\n"
			exit 2
		fi
		notAfter=`echo $certDates | awk -F notAfter= '{print $NF}'`
		expiryDate=$(date -j -f "%b %e %T %Y %Z" "$notAfter" "+%s")
		diff=$(( $expiryDate - $currentDate ))
		warnSeconds=$(($1 * 86400))
		if [ "$diff" -lt "0" ]; then
			# this cert is has already expired! return critical status.
			printf "CRITICAL - $c has expired!\n"
			exit 2
		elif [ "$diff" -lt "$warnSeconds" ]; then
			# this cert is expiring within the warning threshold. return warning status.
	  		printf "WARNING - $c will expire within the next $1 days.\n"
			exit 1
		fi
	fi 
done

# all certificates passed testing. return OK status.
printf "OK - Certificates are valid.\n"
exit 0
