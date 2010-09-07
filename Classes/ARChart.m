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
@property (nonatomic, retain) NSMutableDictionary *postParameters;

@end


@implementation ARChart

@synthesize startDate;
@synthesize endDate;
@synthesize postParameters;

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
	self.postParameters = nil;
	self.startDate = nil;
	self.endDate = nil;
	[super dealloc];
}

// Same as simple encoding, but for extended encoding.
static NSString * const EXTENDED_MAP = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-.";

NSString *extendedEncode(double value, double maxValue) {
	static NSUInteger EXTENDED_MAP_LENGTH;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		EXTENDED_MAP_LENGTH = [EXTENDED_MAP length];
	});
	
	NSString *encodedValue;
	double scaledVal = floor(EXTENDED_MAP_LENGTH * EXTENDED_MAP_LENGTH * value / maxValue);
	if(scaledVal > (EXTENDED_MAP_LENGTH * EXTENDED_MAP_LENGTH) - 1) {
		encodedValue = @"..";
	} else if (scaledVal < 0) {
		encodedValue = @"__";
	} else {
		// Calculate first and second digits and add them to the output.
		double quotient = floor(scaledVal / EXTENDED_MAP_LENGTH);
		double remainder = scaledVal - EXTENDED_MAP_LENGTH * quotient;
		encodedValue = [NSString stringWithFormat:@"%C%C", [EXTENDED_MAP characterAtIndex:quotient], [EXTENDED_MAP characterAtIndex:remainder]];
	}
	return encodedValue;
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
	
	NSMutableString *data = [NSMutableString stringWithFormat:@"e:"];
	NSMutableString *labels = [NSMutableString string];
	NSMutableString *lineSizes = [NSMutableString string];
	NSMutableString *colors = [NSMutableString string];
	NSMutableString *markers = [NSMutableString string];

	NSUInteger countryIndex = 0;
	for (NSString *country in country2entries) {
		NSArray *entriesForCountry = [country2entries objectForKey:country];
		NSMutableString *x = [NSMutableString string];
		NSMutableString *y = [NSMutableString string];
		
		for (ARRankEntry *entry in entriesForCountry) {
			NSString *timeValue = extendedEncode([entry.timestamp timeIntervalSinceDate:self.startDate], timeSpan);
			static double maxValue = 300.0;
			NSString *rankValue = extendedEncode(maxValue-[entry.rank doubleValue], maxValue);
			[x appendString:timeValue];
			[y appendString:rankValue];
		}
		
		[data appendFormat:@"%@,%@", x, y];
		[labels appendString:country];
		[lineSizes appendString:@"2"];
		[colors appendString:[[ARColor colorForCountry:country] hexValue]];
		[markers appendFormat:@"o,FF0000,%d,-1,2", countryIndex];
		if (countryIndex++ < [country2entries count]-1) {
			[data appendString:@","];
			[labels appendString:@"|"];
			[lineSizes appendString:@"|"];
			[colors appendString:@","];
			[markers appendString:@"|"];
		}
	}
	
	[postParameters setObject:data forKey:@"chd"];
	[postParameters setObject:labels forKey:@"chdl"];
	[postParameters setObject:lineSizes forKey:@"chls"];
	[postParameters setObject:colors forKey:@"chco"];
	[postParameters setObject:markers forKey:@"chm"];
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
		
		self.postParameters = [NSMutableDictionary dictionary];
		NSDate *midPoint = [NSDate dateWithTimeInterval:[self.endDate timeIntervalSinceDate:self.startDate]/2 sinceDate:self.startDate];
		NSString *labels = [NSString stringWithFormat:@"0:|%@|%@|%@|1:|300|270|240|210|180|150|120|90|60|30|1|", 
							[[ARChart dateFormatter] stringFromDate:self.startDate],
							[[ARChart dateFormatter] stringFromDate:midPoint],
							[[ARChart dateFormatter] stringFromDate:self.endDate]];
		[postParameters setObject:labels forKey:@"chxl"];
		[postParameters setObject:@"0,10,50,90|1,300,270,240,210,180,150,120,90,60,30,1" forKey:@"chxp"];
		[postParameters setObject:@"1,300,0" forKey:@"chxr"];
		[postParameters setObject:@"x,y" forKey:@"chxt"];
		[postParameters setObject:@"700x420" forKey:@"chs"];
		[postParameters setObject:@"lxy" forKey:@"cht"];
		[postParameters setObject:@"0,10,4,8" forKey:@"chg"]; // Grid
		[postParameters setObject:@"40,20,20,30" forKey:@"chma"]; // Margins

		[self processSortedEntries:sortedEntries];
	}
	return self;
}

- (NSURLRequest *)URLRequest {
	NSURL *url = [NSURL URLWithString:@"http://chart.apis.google.com/chart"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"POST"];
	NSMutableString *postData = [NSMutableString string];
	NSUInteger count = 0;
	for (NSString *param in self.postParameters) {
		[postData appendFormat:@"%@=%@", param, [self.postParameters objectForKey:param]];
		if (count++ < [postParameters count]-1) {
			[postData appendString:@"&"];
		}
	}
	[request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
	return request;
}

- (NSImage *)image {
	NSError *error = nil;
	NSData *imageData = [NSURLConnection sendSynchronousRequest:[self URLRequest] returningResponse:NULL error:&error];
	if (imageData) {
		return [[[NSImage alloc] initWithData:imageData] autorelease];
	} else {
		NSLog(@"Unable to retrieve chart image, error = %@", [error localizedDescription]);
	}
	return nil;
}

@end
