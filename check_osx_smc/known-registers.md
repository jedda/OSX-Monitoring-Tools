Known SMC Registers
===================
This document details known SMC register keys for Apple hardware. These registers can be supplied to [check\_osx\_smc](https://github.com/jedda/OSX-Monitoring-Tools/tree/master/check_osx_smc) to monitor SMC sensor values such as  temperature and fan speeds using Nagios.

Working out new registers
-------------

These registers were figured out with a bit of web sleuthing, and the excellent [smc\_util](https://github.com/alexleigh/smc_util) by Alex Leigh, which can be used to list all registers and data types on a system. If you are trying to figure out registers for non listed hardware, i'd recommend starting there.

Submission
-------------

Should you figure registers that aren't listed here (non listed hardware/missing), and you want to share them, [contact me here](http://jedda.me/contact-jedda/), and i'll be happy to include them in this list.

Hardware List
-------------

####Macmini3,1
- *TC0D* - CPU A Diode
- *TC0H* - CPU A Heatsink
- *TC0P* - CPU A Proximity
- *TH0P* - Hard Drive Bay
- *TN0D* - Northbridge Diode
- *TN0P* - Northbridge Proximity
- *TW0P* - Wireless Module
- *F0Ac* - Internal Fan (Actual Speed)

####Macmini5,1 / Macmini5,2 / Macmini 5,3
- *TA0P* - Ambient Air 1
- *TA1P* - Ambient Air 2
- *TC0D* - CPU A Diode
- *TC0P* - CPU A Proximity
- *TI0P* - Thunderbolt 1 Proximity
- *TI1P* - Thunderbolt 2 Proximity
- *TM0S* - Memory Slot 1
- *TMBS* - Memory Slot 2
- *TM0P* - Memory Slots Proximity
- *TP0P* - Platform Controller Hub Proximity
- *TPCD* - Platform Controller Hub Diode ??
- *Tp0C* - Power Supply
- *TW0P* - Wireless Module
- *F0Ac* - Internal Fan (Actual Speed)

####Macmini6,1 / Macmini6,2
- *TA0P* - Ambient Air 1
- *TA1P* - Ambient Air 2
- *TC0D* - CPU A Diode
- *TC0P* - CPU A Proximity
- *TI0P* - Thunderbolt 1 Proximity
- *TI1P* - Thunderbolt 2 Proximity
- *TM0S* - Memory Slot 1
- *TM0P* - Memory Slots Proximity
- *TP0P* - Platform Controller Hub Proximity
- *TPCD* - Platform Controller Hub Diode ??
- *Tp0C* - Power Supply
- *TW0P* - Wireless Module
- *F0Ac* - Internal Fan (Actual Speed)

####Macpro1,1
- *TA0P* - Ambient Air
- *TC0C* - CPU A Core 1
- *TC1C* - CPU A Core 2
- *TC2C* - CPU B Core 1
- *TC3C* - CPU B Core 2
- *TCAH* - CPU A Heatsink
- *TCBH* - CPU B Heatsink
- *TH0P* - Drive Bay 1
- *TH1P* - Drive Bay 2
- *TH2P* - Drive Bay 3
- *TH3P* - Drive Bay 4
- *TN0H* - Memory Controller Heatsink
- *Tp0C* - Power Supply Inlet
- *Tp1C* - Power Supply Secondary
- *F0Ac* - CPU/RAM Fan (Actual Speed)
- *F1Ac* - Exhaust Fan (Actual Speed)
- *F2Ac* - Expansion Fan (Actual Speed)
- *F3Ac* - Power Supply Fan (Actual Speed)
