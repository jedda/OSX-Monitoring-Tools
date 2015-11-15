#!/bin/bash

#	Check Folder Size - Nagios Probe for OSX
#	Original by Dan Barrett - http://yesdevnull.net
#	Modded by Yvan GODARD - godardyvan@gmail.com - http://www.yvangodard.me

#	v1.2 - 31 Octobre 2015
#	Add options to check write outpout in a specific file for very large folder.
#	Complete refactoring

#	v1.1 - 28 October 2013
#	Added OS X 10.9 Support and fixes a bug where folders with spaces in their name would fail with du.

#	v1.0 - 9 August 2013
#	Initial release.

# Options
version="check_folder_size v1.2 - 2015 - by Yvan Godard http://www.yvangodard.me & Dan Barrett http://yesdevnull.net"
scriptDir=$(dirname "${0}")
scriptName=$(basename "${0}")
scriptNameWithoutExt=$(echo "${scriptName}" | cut -f1 -d '.')
help="no"
folderPath=""
blockSize="m"
warnThresh=""
critThresh=""
withTimeLimit=0
timeLimit=""
thisTime=0
actualSizeK=""
previousSizeK=""
previousSizeM=""
previousSizeG=""
previousDate=""
previousLineBufferFile=""
newLineBufferFile=""
optsCount=0
bufferFolder="/var/${scriptNameWithoutExt}"
bufferFile="${bufferFolder%/}/bufferFile.txt"
messageContent=$(mktemp /tmp/${scriptNameWithoutExt}_messageContent.XXXXX)
duTempScript=$(mktemp /tmp/${scriptNameWithoutExt}_duTempScript.XXXXX)

help () {
	echo ""
	echo "${version}"
	echo ""
	echo "This tool is a Nagios probe for Mac OS X System."
	echo "It's designed to check how large a folder is and to warn or crit if it's over a specified size."
	echo ""
	echo "Disclamer:"
	echo "This tool is provide without any support and guarantee."
	echo ""
	echo "Synopsis:"
	echo "./${scriptName} [-h] | -f <folder> -w <warning> -c <critical>" 
	echo "                       [-b <block size>] [-t <time limit>]"
	echo ""
	echo "Example:"
	echo "./${scriptName} -f /Library/Application\ Support/ -w 2048 -c 4096 -t 45 -b g"
	echo ""
	echo "To print this help:"
	echo "   -h :                Prints this help then exit"
	echo ""
	echo "Mandatory arguments:"
	echo "   -f <folder>:       Complete path to folder you want to check"
	echo "   -w <warning>:      Warning threshold for storage used"
	echo "   -c <critical>:     Critical threshold for storage used"
	echo ""
	echo "Optional options:"
	echo "   -b <block size>:   Block size (i.e. data returned in MB, KB or GB, enter as m, k or g)"
	echo "                      defaults: '-w ${blockSize}' (i.e. ${blockSizeFriendly})"
	echo "   -t <time limit>:   Delay (in seconds) in which the probe must print an outpout."
	echo "                      If the script has not finished calculating the size of the folder within that time"
	echo "                      (on a very large file, for example), the script will display the last state known for this."
	echo ""
}

function endThisScript () {
	[[ ! -z ${3} ]] && echo ${3}
	[[ ! -z $(cat ${messageContent}) ]] && echo "" && cat ${messageContent}
	[[ -e ${messageContent} ]] && rm -R ${messageContent}
	if [[ "${2}" == "removeDuTemp" ]]; then
		[[ -e ${duTemp} ]] && rm -R ${duTemp}
		[[ -e ${duTempScript} ]] && rm -R ${duTempScript}
		[[ -e ${lockFile} ]] && rm -R ${lockFile}
	fi
	[[ ${1} -eq 0 ]] && [[ -e ${lockFile} ]] && rm -R ${lockFile}
	exit ${1}
}

function sizeToK () {
		# Test if function have 2 parameters
		[[ $# -ne 2 ]] && endThisScript 2 "dontRemoveDuTemp" "FATAL ERROR - Function 'sizeToK' used without mandatory parameters!"
		if [[ "${1}" == "k" ]]; then
			echo ${2}
		elif [[ "${1}" == "m" ]]; then
			echo $((${2}*1024))
		elif [[ "${1}" == "g" ]]; then
			echo $((${2}*1024*1024))
		fi
}

function sizeToM () {
		# Test if function have 2 parameters
		[[ $# -ne 2 ]] && endThisScript 2 "dontRemoveDuTemp" "FATAL ERROR - Function 'sizeToM' used without mandatory parameters!"
		if [[ "${1}" == "k" ]]; then
			echo $((${2}/1024))
		elif [[ "${1}" == "m" ]]; then
			echo ${2}
		elif [[ "${1}" == "g" ]]; then
			echo $((${2}*1024))
		fi
}

function sizeToG () {
		# Test if function have 2 parameters
		[[ $# -ne 2 ]] && endThisScript 2 "dontRemoveDuTemp" "FATAL ERROR - Function 'sizeToG' used without mandatory parameters!"
		if [[ "${1}" == "k" ]]; then
			echo $((${2}/1048576))
		elif [[ "${1}" == "m" ]]; then
			echo $((${2}/1024))
		elif [[ "${1}" == "g" ]]; then
			echo ${2}
		fi
}

function processingOutputTest () {
	if [[ "${folderSize}" -ge "${critThresh}" ]]; then
		endThisScript 2 ${1} "CRITICAL - folder is ${folderSize} ${blockSizeFriendly} in size | folderSize=${folderSize};${warnThresh};${critThresh}"
	elif [[ "${folderSize}" -ge "${warnThresh}" ]]; then
		endThisScript 1 ${1} "WARNING - folder is ${folderSize} ${blockSizeFriendly} in size | folderSize=${folderSize};${warnThresh};${critThresh}"
	else
		endThisScript 0 ${1} "OK - folder is ${folderSize} ${blockSizeFriendly} in size | folderSize=${folderSize};${warnThresh};${critThresh}"
	fi
}

function testInteger () {
	test ${1} -eq 0 2>/dev/null
	if [[ $? -eq 2 ]]; then
		echo 0
	else
		echo 1
	fi
}

# Get the flags!
while getopts "ht:f:b:w:c:" opt
	do
		case $opt in
            h)	help="yes"
    				;;
			t)	timeLimit=${OPTARG}
				withTimeLimit=1
					;;
			f)	folderPath=${OPTARG}
				let optsCount=${optsCount}+1
					;;
			b)	blockSize=$(echo ${OPTARG} | sed 'y/KMG/kmg/')
					;;
			w)	warnThresh=${OPTARG}
				let optsCount=${optsCount}+1
					;;
			c)	critThresh=${OPTARG}
				let optsCount=${optsCount}+1
					;;
		esac
done

# Print help then exit
[[ ${help} = "yes" ]] && help && endThisScript 0

# Test mandatory options
[[ "${folderPath}" == "" ]] && echo "> You must provide a file path with -f!" >> ${messageContent}
[[ "${warnThresh}" == "" ]] && echo "> You must provide a warning threshold with -w!" >> ${messageContent}
[[ "${critThresh}" == "" ]] && echo "> You must provide a critical threshold with -c!" >> ${messageContent}
[[ ${optsCount} != "3" ]] && help && endThisScript 2 "dontRemoveDuTemp" "ERROR - All mandatory options are not filled."

#  Test root access
[[ `whoami` != 'root' ]] && endThisScript 2 "dontRemoveDuTemp" "FATAL ERROR - This tool needs a root access. Use 'sudo'."

# Test format blockSize
[[ "${blockSize}" != "k" ]] && [[ "${blockSize}" != "m" ]] && [[ "${blockSize}" != "g" ]] && 
if [[ "${blockSize}" == "m" ]]; then
	blockSizeFriendly="MB"
elif [[ "${blockSize}" == "k" ]]; then
	blockSizeFriendly="KB"
elif [[ "${blockSize}" == "g" ]]; then
	blockSizeFriendly="GB"
else
	echo "You have entered '-b ${blockSize}' but this parameter can only be filled with k (KB), m (MB) or g (GB)." >> ${messageContent}
	endThisScript 2 "ERROR - blocksize parameter can only be k, m or g."
fi

# Test warnThresh and critThresh are integer
[[ $(testInteger ${warnThresh}) -ne 1 ]] && endThisScript 2 "dontRemoveDuTemp" "ERROR - Option -w have to be an integer."
[[ $(testInteger ${critThresh}) -ne 1 ]] && endThisScript 2 "dontRemoveDuTemp" "ERROR - Option -c have to be an integer."

# Test timeLimit is an integer
[[ ${withTimeLimit} -eq 1 ]] && [[ $(testInteger ${timeLimit}) -ne 1 ]] && endThisScript 2 "dontRemoveDuTemp" "ERROR - Option -t have to be an integer."

# Create hash to identify our test
hashTestWithOptions=$(echo "$(dirname ${folderPath%/})/$(basename ${folderPath%/})" | md5)
duTemp=/tmp/${scriptNameWithoutExt}_${hashTestWithOptions}_duTemp

# Add lockfile to avoid multiple instances
lockFile=/tmp/${scriptNameWithoutExt}_${hashTestWithOptions}.lock
lockfile -r 0 ${lockFile} > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
	echo "$(date)" > ${messageContent}
	echo "You tried to launch multiple instances of this tool to monitor the same directory '${folderPath%/}'." >> ${messageContent}
	echo "But, this is not possible. Other instance was launched at the following date: $(date -j -f "%s" "$(stat -f "%m" ${lockFile})" +"%Y/%m/%d %T")." >> ${messageContent}
	endThisScript 2 "dontRemoveDuTemp" "FATAL ERROR - Impossible to run simultam multiple instances of this tool for the same path '${folderPath%/}'"
fi

if [[ ${withTimeLimit} = "1" ]]; then
	# Test access to write on buffer folder & buffer file
	if [[ ! -d ${bufferFolder} ]]; then
		mkdir -p ${bufferFolder}
		[[ $? -ne 0 ]] && endThisScript 2 "dontRemoveDuTemp" "FATAL ERROR - Impossible to create the buffer path '${bufferFolder}'"
	fi
	if [[ ! -f ${bufferFile} ]]; then
		touch ${bufferFile}
		[[ $? -ne 0 ]] && endThisScript 2 "dontRemoveDuTemp" "FATAL ERROR - Impossible to create the buffer file '${bufferFile}'"
	fi
	# Test if a previous outpout is stored in buffer file
	cat ${bufferFile} | grep ${hashTestWithOptions} > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		# Reading previous values
		previousLineBufferFile=$(cat ${bufferFile} | grep ^${hashTestWithOptions})
		# Launching test in background
		[[ -e ${duTemp} ]] && rm -R ${duTemp}
		nohup du -s${blockSize} "${folderPath%/}" | grep -E -o "[0-9]+" 1>${duTemp} 2>&1 &
		# Loop running
		until [[ ${thisTime} -eq $((${timeLimit}-5)) ]]
		do
			# Test if background job is done
			if [[ ! -z $(cat ${duTemp}) ]]; then
				# Test is done in background
				thisTime=$((${timeLimit}-6))
				# Convert actual size to Kb with 'sizeToK' function
				actualSizeK=$(sizeToK ${blockSize} $(cat ${duTemp}))
				# Writing outpout to buffer file
				newLineBufferFile="${hashTestWithOptions};${actualSizeK};$(date +%s)"
				cat ${bufferFile} | sed 's/'"${previousLineBufferFile}"'/'"${newLineBufferFile}"'/g' >> ${bufferFile}.new \
				&& mv ${bufferFile} ${bufferFile}.old && mv ${bufferFile}.new ${bufferFile} && rm ${bufferFile}.old
				folderSize=$(cat ${duTemp})
				echo "$(date)" > ${messageContent}
				echo "Actual size of folder '${folderPath%/}' has been saved on buffer file '${bufferFile}'." >> ${messageContent}
				processingOutputTest "removeDuTemp"
			fi
			sleep 1
			let thisTime=${thisTime}+1
		done
		# Reading previous values
		previousSizeK=$(echo ${previousLineBufferFile} | cut -d ';' -f 2)
		previousDate=$(echo ${previousLineBufferFile} | cut -d ';' -f 3)
		previousDateExplicit=$(date -r ${previousDate})
		echo "$(date)" > ${messageContent}
		echo "The script has not finished calculating the size of the folder within the delay of ${timeLimit} seconds." >> ${messageContent}
		echo "So, output is previous value. Values are dated: ${previousDateExplicit}." >> ${messageContent}
		# Processing previous size to blocksize 
		if [[ "${blockSize}" == "k" ]]; then
			folderSize=${previousSizeK}
		elif [[ "${blockSize}" == "m" ]]; then
			folderSize=$(sizeToM k ${previousSizeK})
		elif [[ "${blockSize}" == "g" ]]; then
			folderSize=$(sizeToG k ${previousSizeK})
		fi
		# Creating temp script
		echo "#!/bin/bash" > ${duTempScript}
		echo 'du -sk '${folderPath%/}' | grep -E -o "[0-9]+" > '${duTemp} >> ${duTempScript}
		echo 'newLineBufferFile="'${hashTestWithOptions}';$(cat '${duTemp}');$(date +%s)"' >> ${duTempScript}
		echo "cat "${bufferFile}" | sed 's/"${previousLineBufferFile}"/'\"\${newLineBufferFile}\"'/g' >> "${bufferFile}".new && mv "${bufferFile}" "${bufferFile}".old && mv "${bufferFile}".new "${bufferFile}" && rm "${bufferFile}".old" >> ${duTempScript}
		echo "[[ -e "${duTemp}" ]] && rm -R "${duTemp} >> ${duTempScript}
		echo "rm ${duTempScript}" >> ${duTempScript}
		echo "rm ${lockFile}" >> ${duTempScript}
		echo "exit 0" >> ${duTempScript}
		# Chmod script to be executed
		chmod +x ${duTempScript}
		# Run this script in background
		(/bin/bash ${duTempScript} > /dev/null 2>&1 &)
		processingOutputTest "dontRemoveDuTemp"
	else
		# First time running test for this folder > writing outpout to Buffer file
		folderSize=$(du -s${blockSize} "${folderPath%/}" | grep -E -o "[0-9]+")
		# echo $folderSize
		# Convert actual size to Kb with 'sizeToK' function
		actualSizeK=$(sizeToK ${blockSize} ${folderSize})
		newLineBufferFile="${hashTestWithOptions};${actualSizeK};$(date +%s)"
		echo ${newLineBufferFile} >> ${bufferFile}
		echo "$(date)" > ${messageContent}
		echo "This is the first time this test is running with option '-t'." >> ${messageContent}
		echo "We don't have any previous value to use if the script has not finished calculating the size of the folder within that time." >> ${messageContent}
		echo "But from now we will have one!" >> ${messageContent}
		echo "" >> ${messageContent}
		echo "$(date)" >> ${messageContent}
		echo "Actual size of folder '${folderPath%/}' has been saved on buffer file '${bufferFile}'." >> ${messageContent}
		processingOutputTest "removeDuTemp"
	fi
elif [[ ${withTimeLimit} = "0" ]]; then
	folderSize=$(du -s${blockSize} "${folderPath%/}" | grep -E -o "[0-9]+")
	processingOutputTest "removeDuTemp"
fi
endThisScript 0 "removeDuTemp"