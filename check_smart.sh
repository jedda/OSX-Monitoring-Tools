#!/bin/bash

#	Check SMART - nagios wrapper for smartmontools
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 20 Feb 2012
#	Initial release.

#	Super simple wrapper script that uses the fantastic smartmontools to report on SMART status of drives.
#	Takes one arguments (disk ident) and users:
#	./check_od_auth.sh diradmin password

# 	Make sure to point to your smartctl location if it is not in the same spot as mine.

# 	We use this on almost all our monitored Macs for the obvious reasons. It has saved us from headaches more than a few times by getting on top of a dying drive in time.

# enable SMART on the drive if it is not already
smartoncmd=`/opt/local/libexec/nagios/smartctl --smart=on $1`

# run smartctl on disk and report on output
if echo `/opt/local/libexec/nagios/smartctl -H $1` | grep -q "PASSED"
	then
  		printf "OK - SMART Passed\n"
  		exit 0
	else
        printf "WARNING - SMART FAILURE!\n"
		exit 1
fi

