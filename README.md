Mac OS X Monitoring Tools
=========================

A collection of scripts and tools to assist in monitoring Mac OS X and essential services with Nagios.

Overviews and use cases for a lot of these can be found in posts at my site:
[http://jedda.me](http://jedda.me)

![Services](http://jedda.me/assets/osx-monitoring/RAM.jpg)

Some of the features of these scripts include:

*   Checking the currency of backups with Time Machine, CrashPlan, and Carbon Copy Cloner
*   Checking memory utilization on Mac OS X
*   Checking the health of Open Directory masters and replicas on Mac OS X Server
*   Checking Open Directory binding & authentication
*   Checking certificate expiry on Mac OS X Server
*   Checking Kerio Connect statistics & performance data
*   Native (no perl, no python) file age check
*   & more!

These scripts and tools were specifically designed to be dependency free, so in the case of all but one or two, they will run on a stock Mac OS X client/server system from 10.4+ onwards. Most of them are pure BASH, with a few Obj-C exceptions that will need to be compiled prior to use.

This is free and unencumbered software released into the public domain - see [LICENSE](https://github.com/jedda/OSX-Monitoring-Tools/blob/master/LICENSE) ([http://unlicense.org/](http://unlicense.org/))

I am happy to chat about any issues you find, or ideas on integrating these scripts into your environment. Feel free to send me an email ([jedda@jedda.me](mailto:jedda@jedda.me "jedda@jedda.me")), or [contact me on AIM (jwignall@mac.com)](aim:goim?screenname=jwignall@mac.com).

