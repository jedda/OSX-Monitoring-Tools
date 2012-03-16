#!/bin/bash

#	Check Open Directory authentication
#	by Jedda Wignall
#	http://jedda.me

#	v1.0 - 21 Feb 2012
#	Initial release.

#	Script that uses dscl -authonly to make sure user authentication is working for your directory.
#	Takes two arguments (user shortname, user password) and checks to make sure that said user can authenticate:
#	./check_od_auth.sh diradmin password

# 	We use this on our OD master to ensure auth is up, and that password server and slapd are happy.

if dscl /LDAPv3/127.0.0.1 -authonly $1 $2; then
	printf "OD authentication succeeded.";
	exit 0
else
	printf "OD authentication FAILED!";
	exit 2
fi
