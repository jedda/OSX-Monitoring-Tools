#!/bin/bash

#	Check Folder Size
#	by Dan Barrett
#	http://yesdevnull.net

#	v1.0 - 9 Aug 2013
#	Initial release.

#	Checks to see how large the folder is, in MB, and warns or crits if over a specified size.

#	Example:
#	./check_folder_size.sh -f /Library/Application\ Support/ -w 2048 -c 4096

folderPath=""
blockSize="m"
blockSizeFriendly="MB"
warnThresh=""
critThresh=""

# Get the flags!
while getopts "f:b:w:c:" opt
	do
		case $opt in
			f ) folderPath=$OPTARG;;
			b ) blockSize=$OPTARG;;
			w ) warnThresh=$OPTARG;;
			c ) critThresh=$OPTARG;;
		esac
done

if [ "$folderPath" == "" ]
then
	printf "ERROR - You must provide a file path with -f!\n"
	exit 2
fi

if [ "$warnThresh" == "" ]
then
	printf "ERROR - You must provide a warning threshold with -w!\n"
	exit 2
fi

if [ "$critThresh" == "" ]
then
	printf "ERROR - You must provide a critical threshold with -c!\n"
	exit 2
fi

if [ "$blockSize" == "k" ]
then
	blockSizeFriendly="KB"
fi

if [ "$blockSize" == "g" ]
then
	blockSizeFriendly="GB"
fi

folderSize=`du -s$blockSize $folderPath | grep -E -o "[0-9]+"`

if [ "$folderSize" -ge "$critThresh" ]
then
	printf "CRITICAL - folder is $folderSize $blockSizeFriendly in size | folderSize=$folderSize;\n"
	exit 2
elif [ "$folderSize" -ge "$warnThresh" ]
then
	printf "WARNING - folder is $folderSize $blockSizeFriendly in size | folderSize=$folderSize;\n"
	exit 1
fi

printf "OK - folder is $folderSize $blockSizeFriendly in size | folderSize=$folderSize;\n"
exit 0