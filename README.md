Mac OS X Monitoring Tools
=========================

A collection of scripts and tools to assist in monitoring Mac OS X and essential services with Nagios.

Overviews and use cases for a lot of these can be found in posts at my site:
[http://jedda.me](http://jedda.me)

![Services](http://jedda.me/assets/osx-monitoring/RAM.jpg)

Some of the features of these scripts include:

*   Checking the currency of backups with Time Machine, CrashPlan, and Carbon Copy Cloner
*   Checking memory utilization on Mac OS X
*   Checking SMC sensors (temperatures/fans) on Apple hardware
*   Checking the health of Open Directory masters and replicas on Mac OS X Server
*   Checking Open Directory binding & authentication
*   Checking the status of tasks scheduled or executed by launchd
*   Checking certificate expiry on Mac OS X Server
*   Checking DHCP & Software Update services on Mac OS X Server
*   Checking Kerio Connect statistics & performance data
*   Native (no perl, no python) file age check
*   Notify via popular notifications platforms Boxcar & Pushover
*   & more!

These scripts and tools were specifically designed to be dependency free, so in the case of all but one or two, they will run on a stock Mac OS X client/server system from 10.4+ onwards. Most of them are pure BASH, with a few Obj-C exceptions that will need to be compiled prior to use.


Support & Feedback:
--------

The project's [Issues Tracker](https://github.com/jedda/OSX-Monitoring-Tools/issues) is the best place to let me know of any specific issues or bugs that you find. I am more than happy to chat about ideas on integrating these scripts into your environment - feel free to send me an email ([jedda@jedda.me](mailto:jedda@jedda.me "jedda@jedda.me")), or contact me with iMessage or AIM ([jwignall@mac.com](imessage://jwignall@mac.com)).


License:
--------

This is free and unencumbered software released into the public domain - see [LICENSE](https://github.com/jedda/OSX-Monitoring-Tools/blob/master/LICENSE) ([http://unlicense.org/](http://unlicense.org/))
