#!/bin/bash

#	Check launchd Tasks
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 1 Aug 2012
#	Initial release.

#	This script calls `launchctl list` and parses the output to report non-zero exit codes for tasks. This is very useful in
#	finding tasks that cannot launch and are 'Throttling respawn', as well as locating bad exit codes for scheduled tasks.

#	!! IMPORTANT: It is important that the script is run as a super user so that system tasks are included - otherwise you are just monitoring
#	tasks in the 'local' domain, which is unlikely to be anything you care about.

#	The preset_exceptions array below exists because some tasks exit with non-zero codes as standard, such as Apple's XProtect
#	anti-malware tool, which exits with a code of 252 when there are no new definitions on Apple's server. The execptions allow
# 	for these kind of known tasks whose exit status is not pertinent to the monitoring of the system.

# 	The -e flag allows you to supply extra exceptions as an argument. This is a comma delimited list of identifiers (see example below).

# 	The -c flag allows you to supply critical processes as an argument. This is a comma delimited list of identifiers (see example below).
#	The default return for finding a process with a non-zero exit code is WARNING. This allows you to define processes that
#	will return CRITICAL.

#	The script takes the above arguments like this:
#	./check_osx_launchd.sh -e com.apple.iCloudHelper,com.apple.NotesMigratorService -c com.apple.servermgrd

preset_exceptions="com.apple.printuitool.agent,com.apple.coreservices.appleid.authentication,com.apple.afpstat-qfa,com.apple.mrt.uiagent,com.apple.printtool.agent,com.apple.accountsd,com.apple.xprotectupdater,com.apple.pfctl"
preset_criticals="org.postgresql.postgres"

# don't edit below this line unless you know what to do

provided_exceptions=""
provided_criticals=""
non_zero=0
critical=0
non_zero_label_array=(  )

while getopts "e:c:" optionName; do
case "$optionName" in
e) provided_exceptions=( $OPTARG );;
c) provided_criticals=( $OPTARG );;
esac
done

exceptions=$preset_exceptions","$provided_exceptions
criticals=$preset_criticals","$provided_criticals

# list all launchd processes, and look at exit codes
launchctl list |  { while read line ; do
	ld_pid=`echo $line | cut -d ' ' -f 1`
	ld_exit=`echo $line | cut -d ' ' -f 2`
	ld_label=`echo $line | cut -d ' ' -f 3`
	
	# skip exceptions
   	case "${exceptions[@]}" in  *"$ld_label"*) continue ;; esac
	# check tasks
	if [ "$ld_pid" != "-" ]; then
		# task is active
		let active++
		#echo "$ld_label is active"
	else
		# task is inactive
		let inactive++
		# look at last exit code
		if [ "$ld_exit" != "0" ]; then
			case "${criticals[@]}" in  *"$ld_label"*) critical=1 ;; esac
			let non_zero++
			non_zero_label_array[${#non_zero_label_array[*]}]="$ld_label"
			
		fi
		
	fi
done

non_zero_labels=`printf ",%s" "${non_zero_label_array[@]}" | cut -c2-`

if [ $non_zero -gt 0 ] && [ $critical == 0 ]; then
	printf "WARNING - daemon/s ($non_zero_labels) exited with a non-zero code! | active=$active; inactive=$inactive; error=$non_zero;\n"
	exit 1
elif [ $non_zero -gt 0 ] && [ $critical == 1 ]; then
	printf "CRITICAL - critical daemon/s ($non_zero_labels) exited with a non-zero code! | active=$active; inactive=$inactive; error=$non_zero;\n"
	exit 2
else
	printf "OK - All daemons are active or exited successfully. | active=$active; inactive=$inactive; error=$non_zero;\n"
	exit 0
fi

}