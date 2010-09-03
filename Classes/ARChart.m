/*
 * Copyright (c) 2010 Todor Dimitrov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "ARChart.h"
#import "ARRankEntry.h"
#import "ARColor.h"


@interface ARChart()

@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, retain) NSMutableString *url;

@end


@implementation ARChart

@synthesize startDate, endDate, url;

+ (NSDateFormatter *)dateFormatter {
	static NSDateFormatter *dateFormatter = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	});
	return dateFormatter;
}

- (void)dealloc {
	self.url = nil;
	self.startDate = nil;
	self.endDate = nil;
	[super dealloc];
}

+ (id)chartForEntries:(NSArray *)entries sorted:(BOOL)sorted {
	return [[[[self class] alloc] initWithEntries:entries sorted:sorted] autorelease];
}

- (void)processSortedEntries:(NSArray *)entries {
	NSTimeInterval timeSpan = [self.endDate timeIntervalSinceDate:self.startDate];
	NSMutableDictionary *country2entries = [NSMutableDictionary dictionary];
	for (ARRankEntry *entry in entries) {
		NSMutableArray *data = [country2entries objectForKey:entry.country];
		if (!data) {
			data = [NSMutableArray array];
			[country2entries setObject:data forKey:entry.country];
		}
		[data addObject:entry];
	}
	
	NSMutableString *data = [NSMutableString string];
	NSMutableString *labels = [NSMutableString string];
	NSMutableString *lineSizes = [NSMutableString string];
	NSMutableString *colors = [NSMutableString string];
	NSMutableString *markers = [NSMutableString string];

	NSUInteger countryIndex = 0;
	for (NSString *country in country2entries) {
		NSArray *entriesForCountry = [country2entries objectForKey:country];
		NSMutableString *x = [NSMutableString string];
		NSMutableString *y = [NSMutableString string];
		
		NSUInteger entryIndex = 0;
		for (ARRankEntry *entry in entriesForCountry) {
			NSTimeInterval normTime = ([entry.timestamp timeIntervalSinceDate:self.startDate]/timeSpan)*100;
			static double maxValue = 300;
			double value = ([entry.rank doubleValue]/maxValue)*100;
			[x appendFormat:@"%.2f", normTime];
			[y appendFormat:@"%.2f", value];
			if (entryIndex++ < [entriesForCountry count]-1) {
				[x appendString:@","];
				[y appendString:@","];
			}
		}
		[data appendFormat:@"%@|%@", x, y];
		[labels appendString:country];
		[lineSizes appendString:@"2"];
		[colors appendString:[[ARColor colorForCountry:country] hexValue]];
		[markers appendFormat:@"o,FF0000,%d,-1,4", countryIndex];
		if (countryIndex++ < [country2entries count]-1) {
			[data appendString:@"|"];
			[labels appendString:@"|"];
			[lineSizes appendString:@"|"];
			[colors appendString:@","];
			[markers appendString:@"|"];
		}
	}
	
	[url appendString:[NSString stringWithFormat:@"&chd=t:%@", data]]; // Data, e.g. 0,30,100|10,20,30|0,40,100|90,80,70
	[url appendString:[NSString stringWithFormat:@"&chdl=%@", labels]]; // Series labels, e.g. Germany|United States
	[url appendString:[NSString stringWithFormat:@"&chls=%@", lineSizes]]; // e.g. 2|2
	[url appendString:[NSString stringWithFormat:@"&chco=%@", colors]]; // Series colors, e.g. 000000,0000FF
	[url appendString:[NSString stringWithFormat:@"&chm=%@", markers]]; // Markers, e.g. o,FF0000,0,-1,4|o,FF0000,1,-1,4
}

- (id)initWithEntries:(NSArray *)entries sorted:(BOOL)sorted {
	if (self = [super init]) {
		assert([entries count] > 1);
		
		NSArray *sortedEntries;
		if (!sorted) {
			sortedEntries = [entries sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" 
																														ascending:YES]]];
		} else {
			sortedEntries = entries;
		}
		self.startDate = ((ARRankEntry *)[sortedEntries objectAtIndex:0]).timestamp;
		self.endDate = ((ARRankEntry *)[sortedEntries lastObject]).timestamp;
		
		assert(startDate);
		assert(endDate);
		assert([startDate isLessThan:endDate]);
		
		self.url = [NSMutableString string];
		[url appendString:@"http://chart.apis.google.com/chart?"];
		[url appendString:[NSString stringWithFormat:@"chxl=0:|%@|%@|1:|300|270|240|210|180|150|120|90|60|30|1|", 
						   [[ARChart dateFormatter] stringFromDate:self.startDate],
						   [[ARChart dateFormatter] stringFromDate:self.endDate]]]; // Axis labels		
		[url appendString:@"&chxp=0,10,90|1,300,270,240,210,180,150,120,90,60,30,1"];
		[url appendString:@"&chxr=1,300,0"];
		[url appendString:@"&chxt=x,y"];
		[url appendString:@"&chs=700x420"];
		[url appendString:@"&cht=lxy"];
		[url appendString:@"&chg=0,10,4,8"]; // Grid
		[url appendString:@"&chma=40,20,20,30"]; // Margins

		[self processSortedEntries:sortedEntries];
	}
	return self;
}

- (NSURL *)URL {
	return [NSURL URLWithString:[self.url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

@end
