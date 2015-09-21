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

#       This script checks the expiry dates of all certificates in a path and returns a warning if needed based on your defined number of days.

version="check_certificate_expiry v2.0 - 2015, Yvan Godard [godardyvan@gmail.com] - http://www.yvangodard.me"
system=$(uname -a)
currentDate=$(date "+%s")
critical=0
warning=0
defaultPathToCheck=1
recursivity=0
systemOs=""
scriptDir=$(dirname "${0}")
scriptName=$(basename "${0}")
scriptNameWithoutExt=$(echo "${scriptName}" | cut -f1 -d '.')
pathToCheck=$(mktemp /tmp/${scriptNameWithoutExt}_pathToCheck.XXXXX)
warningFile=$(mktemp /tmp/${scriptNameWithoutExt}_warningFile.XXXXX)
criticalFile=$(mktemp /tmp/${scriptNameWithoutExt}_criticalFile.XXXXX)
certificatesList=$(mktemp /tmp/${scriptNameWithoutExt}_certificatesList.XXXXX)
messageContent=$(mktemp /tmp/${scriptNameWithoutExt}_messageContent.XXXXX)
numberExpiredCertificates=0
numberWarningCertificates=0
numberProblemCertificates=0

echo ${system} | grep "Darwin" > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
	systemOs="Mac"
	certPath="/etc/certificates"
	extension=".cert.pem"
	recursivity=0
fi
echo ${system} | grep "Linux" > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
	systemOs="Linux"
	certPath="/etc/apache2/ssl"
	extension=".pem"
	recursivity=0
fi

[[ ${systemOs} -ne "Linux" ]] && [[ ${systemOs} -ne "Mac" ]] && error 2 "CRITICAL - This tool doesn't works well on tis OS System!"

help () {
        echo ""
        echo "${version}"
        echo "This script checks the expiry dates of all certificates in a path."
        echo ""
        echo "Disclamer:"
        echo "This tool is provide without any support and guarantee."
        echo ""
        echo "Synopsis:"
        echo "./${scriptName} [-h] | -d <days within warning>" 
        echo "                              [-p <path to check>] [-r] [-e <extension>]"
        echo ""
        echo "To print this help:"
        echo "   -h:                        prints this help then exit"
        echo ""
        echo "Mandatory options:"
        echo "   -d <days within warning>:  number of days within expiration to warn"
        echo ""
        echo "Optional options:"
        echo "   -p <path to check>:        the full path of the directory to check"
        echo "                              (e.g.: '/etc/apache2/ssl/certs', default '${certPath}')"
        echo "                              if you want to check more than one directory, separate path with '%'"
        echo "                              (e.g.: '-p /etc/certs\%/etc/certificates'"
        echo "   -r:                        check the path with recursivity"
        echo "   -e <extension>:            extension of certificats to check (e.g.: '-e .certifs.pem', default: '${extension}')"
        alldone 0
}

function alldone () {
        [[ -e ${criticalFile} ]] && rm ${criticalFile}
        [[ -e ${warningFile} ]] && rm ${warningFile}
        [[ -e ${pathToCheck} ]] && rm ${pathToCheck}
        [[ -e ${certificatesList} ]] && rm ${certificatesList}
        [[ -e ${messageContent} ]] && rm ${messageContent}
        exit ${1}
}

function error () {
        [[ ! -z ${2} ]] && echo ${2}
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
                let optsCount=${optsCount}+1
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
		[[ ${recursivity} -eq 1 ]] && find ${directoryToCheck%/} -type f -name "*${extension}" >> ${certificatesList}
		[[ ${recursivity} -eq 0 ]] && find ${directoryToCheck%/} -maxdepth 1 -type f -name "*${extension}" >> ${certificatesList}
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
            let numberProblemCertificates=${numberProblemCertificates}+1
            critical=1
        fi
        notAfter=$(echo ${certDates} | awk -F notAfter= '{print $NF}')
        if [[ ${systemOs} == "Mac" ]]; then
        	date -j -f "%b %e %T %Y %Z" "${notAfter}" "+%s" > /dev/null 2>&1
        	if [[ $? -ne 0 ]]; then
        		printf "> ${certificate} - expiry date could not be found by openssl\n" >> ${warningFile}
                let numberProblemCertificates=${numberProblemCertificates}+1
        		warning=1
        	else
        		expiryDate=$(date -j -f "%b %e %T %Y %Z" "${notAfter}" "+%s")
        	fi
        elif [[ ${systemOs} == "Linux" ]]; then
        	date --date="${notAfter}" "+%s" > /dev/null 2>&1
        	if [[ $? -ne 0 ]]; then
        		printf "> ${certificate} - expiry date could not be found by openssl\n" >> ${warningFile}
                let numberProblemCertificates=${numberProblemCertificates}+1
        		warning=1
        	else
        		expiryDate=$(date --date="${notAfter}" "+%s")
        	fi
        fi
        diff=$(( ${expiryDate} - ${currentDate} ))
        warnSeconds=$((${days} * 86400))
        if [[ "${diff}" -lt "0" ]]; then
            # this cert is has already expired! return critical status.
            printf "> ${certificate} has expired!\n" >> ${criticalFile}
            let numberExpiredCertificates=${numberExpiredCertificates}+1
            critical=1

        elif [[ "${diff}" -lt "${warnSeconds}" ]]; then
            # this cert is expiring within the warning threshold. return warning status.
            delay=$((${diff} / 86400))
            printf "> ${certificate} will expire within the next ${days} days.\n" >> ${warningFile}
            printf "  delay until expiration : ${delay} day(s)\n" >> ${warningFile}
            let numberWarningCertificates=${numberWarningCertificates}+1
            warning=1
        fi 
done

# Generate first line message for Centreon
[[ ${numberExpiredCertificates} -eq 1 ]] && echo "1 certificate has expired" >> ${messageContent}
[[ ${numberExpiredCertificates} -gt 1 ]] && echo "${numberExpiredCertificates} ceertificates had expired" >> ${messageContent}

[[ ${numberProblemCertificates} -eq 1 ]] && echo "Problem to read 1 certificate" >> ${messageContent}
[[ ${numberProblemCertificates} -gt 1 ]] && echo "Problem to read ${numberProblemCertificates} certificates" >> ${messageContent}

[[ ${numberWarningCertificates} -eq 1 ]] && echo "1 certificate will expire within the next ${days} days" >> ${messageContent}
[[ ${numberWarningCertificates} -gt 1 ]] && echo "${numberWarningCertificates} certificates will expire within the next ${days} days" >> ${messageContent}

messageContentLine=$(cat ${messageContent} | perl -p -e 's/\n/ - /g' | awk 'sub( "...$", "" )')

if [[ ${critical} -eq "1" ]]; then
        [[ ! -z $(cat ${criticalFile}) ]] && printf "CRITICAL - ${messageContentLine}" && printf "\n-- CRITICAL --\n" && cat ${criticalFile}
        [[ ! -z $(cat ${warningFile}) ]] && printf "\n-- WARNING --\n" && cat ${warningFile}
        alldone 2
elif [[ ${warning} -eq "1" ]]; then
        [[ ! -z $(cat ${warningFile}) ]] && printf "WARNING - ${messageContentLine}" && printf "\n-- WARNING --\n" && cat ${warningFile}
        alldone 1
else
        error 0 "OK - Certificates are valid."
fi

alldone 0