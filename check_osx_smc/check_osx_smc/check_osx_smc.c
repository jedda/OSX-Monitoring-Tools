//
//  main.c
//  check_osx_smc
//
//  Created by Jedda Wignall on 11/05/12.
//  Copyright (c) 2012 Streetwise Software Pty. Ltd. All rights reserved.
//

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <IOKit/IOKitLib.h>

static io_connect_t connect;

int main (int argc, const char * argv[])
{
    kern_return_t result;
    mach_port_t   masterPort;
    io_iterator_t iterator;
    io_object_t   device;
    io_connect_t  connect;
    
    IOMasterPort(MACH_PORT_NULL, &masterPort);

    CFMutableDictionaryRef matchingDictionary = IOServiceMatching("AppleSMC");
    result = IOServiceGetMatchingServices(masterPort, matchingDictionary, &iterator);
    if (result != kIOReturnSuccess)
    {
        printf("Error: IOServiceGetMatchingServices() = %08x\n", result);
        return 1;
    }
    
    device = IOIteratorNext(iterator);
    IOObjectRelease(iterator);
    if (device == 0)
    {
        printf("Error: no SMC found\n");
        return 1;
    }
    
    result = IOServiceOpen(device, mach_task_self(), 0, &connect);
    IOObjectRelease(device);
    if (result != kIOReturnSuccess)
    {
        printf("Error: IOServiceOpen() = %08x\n", connect);
        return 1;
    }

    printf("Hello, World!\n");
    return 0;
}


