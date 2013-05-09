check\_osx\_smc
=========================

A Nagios plugin to read and report SMC readings (temperature sensors, fan speed sensors) on Apple hardware. It is part of [Mac OS X Monitoring Tools](https://github.com/jedda/OSX-Monitoring-Tools), a collection of scripts and tools to assist in monitoring Mac OS X and essential services with Nagios.

####Usage
./check_osx_smc [options]

####Options
*	-r                      : comma delimited list of smc registers to read
*	-w  [required]          : comma delimited list of warning thresholds
*	-c  [required]          : comma delimited list of critical thresholds
*	-s [required]           : temperature scale to use. c for celcius, f for fahrenheit
*	-h                      : display help

####Example
./check_osx_smc -r TA0P,TC0D,F0Ac -w 75,85,3800 -c 85,100,5200 -s c

This example on a 2011 Mac mini Server would check TA0P (Ambient Air 1), TC0D (CPU Diode), and F0Ac (Primary Fan Speed). It would return values in degrees Celcius, return warning status on values above values of 75,85,3800 respectively, and return critical status above values of 85,100,5200 respectively.

####SMC Registers
This plugin currently accepts and processes SMC registers for temperature and fan speed. There are plans in the future to implement power values too. It is up to the end user to provide register keys to the script, but a list of known values for current hardware is located at: [known-registers](https://github.com/jedda/OSX-Monitoring-Tools/blob/master/check_osx_smc/known-registers.md)

####Source Code & Licensing
The source code of this plugin is available [here](https://github.com/jedda/OSX-Monitoring-Tools/blob/master/check_osx_smc/).
This plugin includes and makes use of 'Apple System Management Control (SMC) Tool' by devnull, which is licensed under the GNU General Public License. All other parts of this plugin are made available under an unlicense, and is free and unencumbered software released into the public domain. Please refer to the [LICENSE](https://github.com/jedda/OSX-Monitoring-Tools/blob/master/LICENSE) for further details .

####Support, Bugs & Issues:
This plugin is free and open-source, and as such, support is limited - queries can be directed to [this contact page](http://jedda.me/contact-jedda/). Any issues or bugs should be registered on the project's GitHub [Issue Tracker](https://github.com/jedda/OSX-Monitoring-Tools/issues).
