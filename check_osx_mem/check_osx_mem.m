#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import <mach/mach.h>
#import <mach/mach_error.h>
#import <sys/sysctl.h>
#import <unistd.h>

//	check_osx_mem
//	by Jedda Wignall
//	http://jedda.me

//	v1.1 - 12 Mar 2012
//	Fixed issue with performance data.

//	v1.0 - 12 Mar 2012
//	Initial release.

//	Tool to report OSX memory utilization to nagios and Groundwork server.
//	Requires -w and -c values as percentage utilization. Returns lots of performance data.
//	./check_osx_mem -w 65.00 -c 85.00


int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	BOOL warn = FALSE, crit = FALSE;
	NSNumber *warningThreshold, *criticalThreshold;
	
	// get our warning value
	if ([[[NSProcessInfo processInfo] arguments] containsObject:@"-w"]) {
		warningThreshold = [NSNumber numberWithFloat: [[[[NSProcessInfo processInfo] arguments] objectAtIndex: [[[NSProcessInfo processInfo] arguments] indexOfObject:@"-w"] + 1 ] floatValue] ];
		//NSLog(@"Warning threshold is: %@", warningThreshold);
    } else {
		// no warning threshold defined. error out.
		NSLog(@"No warning threshold defined. You must set a warning threshold with -w!");
		return 1;
	}
	
	// get our critical value
	if ([[[NSProcessInfo processInfo] arguments] containsObject:@"-c"]) {
		criticalThreshold = [NSNumber numberWithFloat: [[[[NSProcessInfo processInfo] arguments] objectAtIndex: [[[NSProcessInfo processInfo] arguments] indexOfObject:@"-c"] + 1 ] floatValue] ];
		//NSLog(@"Warning threshold is: %@", criticalThreshold);
	} else {
		// no warning threshold defined. error out.
		NSLog(@"No critical threshold defined. You must set a critical threshold with -c!");
		return 1;
	}
	
	mach_port_t host = mach_host_self();
	if (!host) {
		NSLog(@"Could not get mach reference.");
		return 2;
	}
    
    vm_statistics_data_t vmStats;
	mach_msg_type_number_t vmCount = HOST_VM_INFO_COUNT;
	if (host_statistics(host, HOST_VM_INFO, (host_info_t)&vmStats, &vmCount) != KERN_SUCCESS) {
        NSLog(@"Could not get mach reference.");
        return 2;
	}
    
    NSInteger active = (NSInteger)((natural_t)vmStats.active_count) * (NSInteger)((natural_t)vm_page_size);
	NSInteger inactive = (NSInteger)((natural_t)vmStats.inactive_count) * (NSInteger)((natural_t)vm_page_size);
    NSInteger wired = (NSInteger)((natural_t)vmStats.wire_count) * (NSInteger)((natural_t)vm_page_size);
	NSInteger free = (NSInteger)((natural_t)vmStats.free_count) * (NSInteger)((natural_t)vm_page_size);
    NSInteger used = active + wired;
    NSInteger total = active + inactive + free + wired;

    // work out our memory percentage    
	double percentage = ((double)used/(double)total) * 100.00 ;
	
    // build our performance data string
    NSString *performance = [NSString stringWithFormat:@"active=%f; wired=%f; inactive=%f; free=%f; total=%f; utilization=%f;\r\n", (double)(active/1048576), (double)(wired/1048576), (double)(inactive/1048576), (double)(free/1048576), (double)(total/1048576), (double)percentage];
    
	// check critical
	if ([criticalThreshold compare:[NSNumber numberWithFloat:percentage]] == NSOrderedAscending) {
		printf([[NSString stringWithFormat:@"CRITICAL: %f percent memory utilization | %@", percentage, performance] cString]);
		[pool drain];
		return 2;
	}
	
	// check warning
	if ([warningThreshold compare:[NSNumber numberWithFloat:percentage]] == NSOrderedAscending) {
		printf([[NSString stringWithFormat:@"WARNING: %f percent memory utilization | %@", percentage, performance] cString]);
		[pool drain];
		return 1;
	}
	
	printf([[NSString stringWithFormat:@"OK: %f percent memory utilization | %@", percentage, performance] cString]);
	
	[pool drain];
    return 0;
}
