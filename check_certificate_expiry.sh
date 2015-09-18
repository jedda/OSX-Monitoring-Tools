#!/bin/bash

#       Check Certificate Expiry
#       Original script by Jedda Wignall - http://jedda.me
#       Modded to work both on Mac & Linux by Yvan GODARD - godardyvan@gmail.com - http://www.yvangodard.me

#       v2.0 - 18 Sep 2015
#       Modded to work both on Mac & Linux.
#		Complete refactoring

#       v1.1 - 17 Sep 2012
#       Fixed script to throw proper critical error if a cert cannot be loaded by openssl.

#       v1.0 - 20 Mar 2012
#       Initial release.

#       This script checks the expiry dates of all certificates in the /etc/certificates directory, and returns a warning if needed based on your defined number of days.
#       Takes 1 argument - the minimum number of days between today and cert expiry to throw a warning:
#
#       check_certificate_expiry.sh -d 7 -p /etc/apache2/ssl
#       Warns if a certificate is set to expire in the next 7 days.

version="check_certificate_expiry v2.0 - 2015, Yvan Godard [godardyvan@gmail.com] - http://www.yvangodard.me"
system=$(uname -a)
currentDate=$(date "+%s")
critical=0
warning=0
defaultPathToCheck=1
recursivity=0
scriptDir=$(dirname "${0}")
scriptName=$(basename "${0}")
scriptNameWithoutExt=$(echo "${scriptName}" | cut -f1 -d '.')
pathToCheck=$(mktemp /tmp/${scriptNameWithoutExt}_pathToCheck.XXXXX)
warningFile=$(mktemp /tmp/${scriptNameWithoutExt}_warningFile.XXXXX)
criticalFile=$(mktemp /tmp/${scriptNameWithoutExt}_criticalFile.XXXXX)
certificatesList=$(mktemp /tmp/${scriptNameWithoutExt}_certificatesList.XXXXX)

cat ${system} | grep "Darwin" > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
	systemOs="Mac"
	certPath="/etc/certificates"
	extension=".cert.pem"
	recursivity=0
fi
cat ${system} | grep "Linux" > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
	systemOs="Linux"
	certPath="/etc/apache2/ssl"
	extension=".pem"
	recursivity=0
fi

[[ ${systemOs} -ne "Linux" ]] && [[ ${systemOs} -ne "Mac" ]] && error 2 "CRITICAL - This tool doesn't works well on tis OS System!"

help () {
        printf "\n${version}\n"
        printf "\nThis script checks the expiry dates of all certificates in a path.\n"
        printf "\nDisclamer:\n"
        printf "\nThis tool is provide without any support and guarantee.\n"
        printf "\nSynopsis:\n"
        printf "./$scriptName [-h] | -d <days within warning>\n" 
        printf "                       [-p <path to check>] [-r] [-e <extension>]\n"
        printf "\nTo print this help:\n"
        printf "\t-h:                               prints this help then exit\n"
        printf "\nMandatory options:\n"
        printf "\t-d <days within warning>:         number of days within expiration to warn\n"
        printf "\nOptional options:\n"
        printf "\t-p <path to check>:               the full path of the directory to check (e.g.: '/etc/apache2/ssl/certs')\n"
        printf "\t                                  if you want to check more than one directory, separate path with '%'\n"
        printf "\t                                  (e.g.: '-p /etc/certs%/etc/certificates'\n"
        printf "\t-r:                               check the path with recursivity\n"
        printf "\t-e <extension>:                   extension of certificats to check (e.g.: '.certifs.pem', default: '${extension}')\n"
        alldone 0
}

function alldone () {
        [[ -e ${criticalFile} ]] && rm ${criticalFile}
        [[ -e ${warningFile} ]] && rm ${warningFile}
        [[ -e ${pathToCheck} ]] && rm ${pathToCheck}
        [[ -e ${certificatesList} ]] && rm ${certificatesList}
        exit ${1}
}

function error () {
        [[ ! -z ${2} ]] && printf ${2}
        alldone ${1}
}

# Parameters tests
optsCount=0
while getopts "hrd:p:e:" option
do
    case "$option" in
            h)	help="yes"
                ;;
            d)  days=${OPTARG}
                let optsCount=$optsCount+1
                ;;
            p)  [[ ! -z ${OPTARG} ]] && defaultPathToCheck=0 && echo ${OPTARG} | perl -p -e 's/%/\n/g' | perl -p -e 's/ //g' | awk '!x[$0]++' >> ${pathToCheck}
				;;
            e)	extension=${OPTARG}
				;;
			r)	recursivity=1
				;;
    esac
done

if [[ ${optsCount} != "1" ]]; then
        help
        error 3 "CRITICAL - Mandatory parameters needed!"
fi

[[ ${help} = "yes" ]] && help

echo ${days} | grep "^[ [:digit:] ]*$" > /dev/null 2>&1
[[ $? -ne 0 ]] && error 4 "CRITICAL - Parameter '-d ${days}' is not coorect. Must be an interger."

[[ ${defaultPathToCheck} -eq 1 ]] && printf "${certPath}" > ${pathToCheck}

for directoryToCheck in $(cat ${pathToCheck})
do
	if [[ -d ${directoryToCheck} ]]; then
		[[ ${recursivity} -eq 1 ]] && find ${directoryToCheck%/} -type f -name "${extension}" >> ${certificatesList}
		[[ ${recursivity} -eq 0 ]] && find ${directoryToCheck%/} -type f -name "${extension}" -maxdepth 1 >> ${certificatesList}
	fi
done

[[ -z $(cat ${certificatesList}) ]] && error 5 "CRITICAL - No certificate to check. Please be sure your parameters are OK."

for certificate in $(cat ${certificatesList})
do
        # read the dates on each certificate
        certDates=$(openssl x509 -noout -in "${certificate}" -dates 2>/dev/null)
        if [[ -z "$certDates" ]]; then
            # this cert could not be read.
            printf "> ${certificate} could not be loaded by openssl\n" >> ${criticalFile}
            critical=1
        fi
        notAfter=$(echo ${certDates} | awk -F notAfter= '{print $NF}')     
        expiryDate=$(date --date="${notAfter}" "+%s")
        diff=$(( ${expiryDate} - ${currentDate} ))
        warnSeconds=$((${days} * 86400))
        if [[ "${diff}" -lt "0" ]]; then
            # this cert is has already expired! return critical status.
            printf "> ${certificate} has expired!\n" >> ${criticalFile}
            critical=1
        elif [[ "${diff}" -lt "${warnSeconds}" ]]; then
            # this cert is expiring within the warning threshold. return warning status.
            delay=$((${diff} / 86400))
            printf "> ${certificate} will expire within the next ${days} days.\n" >> ${warningFile}
            printf "  delay until expiration : ${delay} day(s)\n" >> ${warningFile}
            warning=1
        fi 
done

if [[ ${critical} -eq "1" ]]; then
        [[ ! -z $(cat ${criticalFile}) ]] && printf "\n-- CRITICAL --\n" && cat ${criticalFile}
        [[ ! -z $(cat ${warningFile}) ]] && printf "\n-- WARNING --\n" && cat ${warningFile}
        alldone 2
elif [[ ${warning} -eq "1" ]]; then
        [[ ! -z $(cat ${warningFile}) ]] && printf "\n-- WARNING --\n" && cat ${warningFile}
        alldone 1
else
        alldone 0 "OK - Certificates are valid.\n"
fi

alldone 0