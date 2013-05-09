//	check_osx_mem
//	by Jedda Wignall
//	http://jedda.me

//	v1.0 - 07 May 2013
//	Initial release.

//	Nagios plugin to read and report SMC readings (temperature, fan speed) on Apple hardware.
//  Part of the Mac OS X Monitoring Tools project [https://github.com/jedda/OSX-Monitoring-Tools]
//  https://github.com/jedda/OSX-Monitoring-Tools/tree/master/check_osx_smc

#import <Foundation/Foundation.h>
#include <stdio.h>
#include "smc.h"

#define VERSION               "1.0"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        
        // do we need to print help?
        if ([[[NSProcessInfo processInfo] arguments] containsObject:@"-h"] || [[[NSProcessInfo processInfo] arguments] count] == 1) {
            printf("check_smc_osx version ");
            printf(VERSION);
            printf("\n");
            printf("by Jedda Wignall (http://jedda.me)");
            printf("\n\n");
            printf("Nagios plugin to read and report SMC readings (temperature, fan speed) on Apple hardware.");
            printf("\n\n");
            printf("Usage: ");
            printf([[[[NSProcessInfo processInfo] arguments] objectAtIndex:0] cString]);
            printf(" [options]");
            printf("\n\n");
            printf("Options:\n");
            printf("-r <registers> [required]           : comma delimited list of smc registers to read\n");
            printf("-w <thresholds> [required]          : comma delimited list of warning thresholds\n");
            printf("-c <thresholds> [required]          : comma delimited list of critical thresholds\n");
            printf("-s <scale> [required]               : temperature scale to use. c for celcius, f for fahrenheit\n");
            printf("-h                                  : display this help\n");
            printf("\n");
            printf("Example:\n");
            printf("./check_osx_smc -r TA0P,TC0D,F0Ac -w 75,85,3800 -c 85,100,5200 -s c\n\n");
            printf("This example on a 2011 Mac mini Server would check TA0P (Ambient Air 1), TC0D (CPU Diode), and F0Ac (Primary Fan Speed). It would return values in degrees Celcius, return warning status on values above values of 75,85,3800 respectively, and return critical status above values of 85,100,5200 respectively.\n\n");
            printf("SMC Registers:\n");
            printf("This plugin currently accepts and processes SMC registers for temperature and fan speed. There are plans in the future to implement power values too. It is up to the end user to provide register keys to the script, but a list of known values for current hardware is located at: https://github.com/jedda/OSX-Monitoring-Tools/blob/master/check_osx_smc/known-registers.md\n\n");
            printf("Source Code & Licensing:\n");
            printf("The source code of this plugin is available at: https://github.com/jedda/OSX-Monitoring-Tools/blob/master/check_osx_smc/\n");
            printf("This plugin includes and makes use of 'Apple System Management Control (SMC) Tool' by devnull, which is licensed under the GNU General Public License. All other parts of this plugin are made available under an unlicense, and is free and unencumbered software released into the public domain. Please refer to the LICENSE for further details: https://github.com/jedda/OSX-Monitoring-Tools/blob/master/LICENSE.\n\n");
            printf("Support, Bugs & Issues:\n");
            printf("This plugin is free and open-source, and as such, support is limited - queries can be directed to http://jedda.me/contact-jedda/. Any issues or bugs should be registered on GitHub here: https://github.com/jedda/OSX-Monitoring-Tools/issues\n");
            return 3;
        }
        
        BOOL warn = FALSE, crit = FALSE;
        NSArray *smcRegisters, *warnThresholds, *critThresholds;
        NSMutableArray *performance = [NSMutableArray array];
        NSMutableArray *status = [NSMutableArray array];
        NSString *scale;
        
        NSNumberFormatter *tempFormatter = [[NSNumberFormatter alloc] init];
        tempFormatter.format = @"#0.0";
        NSNumberFormatter *fanFormatter = [[NSNumberFormatter alloc] init];
        fanFormatter.format = @"#";
        NSNumberFormatter *performanceFormatter = [[NSNumberFormatter alloc] init];
        performanceFormatter.format = @"#0.0000";
        
        // get our smc registers
        if ([[[NSProcessInfo processInfo] arguments] containsObject:@"-r"]) {
            NSString* regString = [[[NSProcessInfo processInfo] arguments] objectAtIndex: [[[NSProcessInfo processInfo] arguments] indexOfObject:@"-r"] + 1 ];
            smcRegisters = [regString componentsSeparatedByString:@","];
        } else {
            // no smc registers defined. error out.
            printf("No SMC registers defined. You must supply at least one register with -r! Use -h to view help.");
            return 3;
        }
        
        // get our warning thresholds
        if ([[[NSProcessInfo processInfo] arguments] containsObject:@"-w"]) {
            NSString* warnString = [[[NSProcessInfo processInfo] arguments] objectAtIndex: [[[NSProcessInfo processInfo] arguments] indexOfObject:@"-w"] + 1 ];
            warnThresholds = [warnString componentsSeparatedByString:@","];
        } else {
            // no warning threshold defined. error out.
            printf("No warning threshold defined. You must set a warning threshold with -w! Use -h to view help.");
            return 3;
        }
        
        // get our crtitical thresholds
        if ([[[NSProcessInfo processInfo] arguments] containsObject:@"-c"]) {
            NSString* critString = [[[NSProcessInfo processInfo] arguments] objectAtIndex: [[[NSProcessInfo processInfo] arguments] indexOfObject:@"-c"] + 1 ];
            critThresholds = [critString componentsSeparatedByString:@","];
        } else {
            // no critical threshold defined. error out.
            printf("No critical threshold defined. You must set a critical threshold with -c! Use -h to view help.");
            return 3;
        }
        
        // get our temperature scale
        if ([[[NSProcessInfo processInfo] arguments] containsObject:@"-s"]) {
           scale = [[[NSProcessInfo processInfo] arguments] objectAtIndex: [[[NSProcessInfo processInfo] arguments] indexOfObject:@"-s"] + 1 ];
        } else {
            // no temperature scale defined. error out.
            printf("No temperature scale defined. You must supply a value to -s of either c (Celsius) or f (Fahrenheit)! Use -h to view help.");
            return 3;
        }
        
        // ensure that registers and thresholds have been evenly defined
        if (smcRegisters.count != warnThresholds.count || warnThresholds.count != critThresholds.count) {
            printf("The number of supplied SMC registers and warning/critical thresholds does not match. Please ensure you are supplying the same number of each.");
            return 3;
        }
        
        // read the smc registers
        
        SMCOpen();
        
        for (NSString *registerKey in smcRegisters) {
            
            double value = 0.0;
            double warnThreshold = [[warnThresholds objectAtIndex:[smcRegisters indexOfObject:registerKey]] doubleValue];
            double critThreshold = [[critThresholds objectAtIndex:[smcRegisters indexOfObject:registerKey]] doubleValue];
            
            if ([registerKey hasPrefix:@"T"]) {
                // this is a temperature sensor
                value = SMCGetTemperature([registerKey cStringUsingEncoding:NSUTF8StringEncoding]);
                // do we need to convert to fahrenheit?
                if ([scale isEqualToString:@"f"]) {
                    value = ((9.0 / 5.0) * value) + 32;
                }
                if (value >= critThreshold || value == 0.0) {
                    crit = TRUE;
                    [status addObject:[NSString stringWithFormat:@"%@ is %@%@", registerKey, [tempFormatter stringFromNumber:[NSNumber numberWithDouble:value]] , [scale uppercaseString]]];
                } else if (value >= warnThreshold) {
                    warn = TRUE;
                    [status addObject:[NSString stringWithFormat:@"%@ is %@%@", registerKey, [tempFormatter stringFromNumber:[NSNumber numberWithDouble:value]] , [scale uppercaseString]]];
                }
            } else if ([registerKey hasPrefix:@"F"]) {
                // this is a fan sensor
                value = (double)SMCGetFanRPM([registerKey cStringUsingEncoding:NSUTF8StringEncoding]);
                if (value >= critThreshold || value == 0.0) {
                    crit = TRUE;
                    [status addObject:[NSString stringWithFormat:@"%@ at %@rpm", registerKey, [fanFormatter stringFromNumber:[NSNumber numberWithDouble:value]]]];
                } else if (value >= warnThreshold) {
                    warn = TRUE;
                    [status addObject:[NSString stringWithFormat:@"%@ at %@rpm", registerKey, [fanFormatter stringFromNumber:[NSNumber numberWithDouble:value]]]];
                }
            }
            
            // add to our array of performance data
            [performance addObject:[NSString stringWithFormat:@"%@=%@;%@;%@;", registerKey, [performanceFormatter stringFromNumber:[NSNumber numberWithDouble:value]], [performanceFormatter stringFromNumber:[NSNumber numberWithDouble:warnThreshold]], [performanceFormatter stringFromNumber:[NSNumber numberWithDouble:critThreshold]]]];

        }
        
        SMCClose();
    
        if (crit == TRUE) {
            printf([[NSString stringWithFormat:@"CRITICAL - %@ | %@\n", [status componentsJoinedByString:@", "], [performance componentsJoinedByString:@" "]] cString]);
            return 2;
        } else if (warn == TRUE) {
            printf([[NSString stringWithFormat:@"WARNING - %@ | %@\n", [status componentsJoinedByString:@", "], [performance componentsJoinedByString:@" "]] cString]);
            return 1;
        } else {
            printf([[NSString stringWithFormat:@"OK - All sensors within threshold! | %@\n", [performance componentsJoinedByString:@" "]] cString]);
            return 0;
        }
        

    }
}

