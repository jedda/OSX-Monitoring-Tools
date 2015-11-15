#!/bin/bash

#	Check Folder Size
#	by Dan Barrett
#	http://yesdevnull.net

#	v1.1 - 28 October 2013
#	Added OS X 10.9 Support and fixes a bug where folders with spaces in their name would fail with du.

#	v1.0 - 9 August 2013
#	Initial release.

#	Checks to see how large the folder is and warns or crits if over a specified size.
#	Defaults to MB

#	Arguments:
#	-f	Path to folder
#	-b	Block size (i.e. data returned in MB, KB or GB - enter as m, k or g)
#	-w	Warning threshold for storage used
#	-c	Critical threshold for storage used

#	Example:
#	./check_folder_size.sh -f /Library/Application\ Support/ -w 2048 -c 4096

#	Supports:
#	Untested but I'm sure it works fine on OS X 10.6 and 10.7
#	* OS X 10.8.x
#	* OS X 10.9

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

folderSize=`du -s$blockSize "$folderPath" | grep -E -o "[0-9]+"`

if [ "$folderSize" -ge "$critThresh" ]
then
	printf "CRITICAL - folder is $folderSize $blockSizeFriendly in size | folderSize=$folderSize;$warnThresh;$critThresh;\n"
	exit 2
elif [ "$folderSize" -ge "$warnThresh" ]
then
	printf "WARNING - folder is $folderSize $blockSizeFriendly in size | folderSize=$folderSize;$warnThresh;$critThresh;\n"
	exit 1
fi

printf "OK - folder is $folderSize $blockSizeFriendly in size | folderSize=$folderSize;$warnThresh;$critThresh;\n"
exit 0