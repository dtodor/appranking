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

#import "ARChartViewController.h"
#import "ARRankEntry.h"
#import "ARStorageManager.h"
#import "ARChart.h"
#import "ARColor.h"


@interface ARChartViewController()

@property (nonatomic, retain) NSArray *chartCountries;
@property (nonatomic, retain) NSArray *timeFrameChoices;

@end


@implementation ARChartViewController

@synthesize chartCountries;
@synthesize allCountries;
@synthesize application;
@synthesize category;
@synthesize chartImageView;
@synthesize timeFrameChoices;
@synthesize selectedTimeFrame;
@synthesize fromDate;
@synthesize untilDate;

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"allCountries"];
	[self removeObserver:self forKeyPath:@"selectedTimeFrame"];
	
	self.fromDate = nil;
	self.untilDate = nil;
	self.selectedTimeFrame = nil;
	self.timeFrameChoices = nil;
	self.chartImageView = nil;
	self.application = nil;
	self.category = nil;
	self.allCountries = nil;
	self.chartCountries = nil;
	[super dealloc];
}

#define HOUR 3600
#define DAY 24*HOUR

- (void)awakeFromNib {
	[self addObserver:self forKeyPath:@"selectedTimeFrame" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"allCountries" options:NSKeyValueObservingOptionNew context:NULL];

	self.timeFrameChoices = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:7*DAY], @"value", @"Last 7 days", @"name", nil],
							 [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:30*DAY], @"value", @"Last 30 days", @"name", nil],
							 [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:90*DAY], @"value", @"Last 90 days", @"name", nil],
							 [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], @"value", @"Custom", @"name", nil],
							 nil];
	self.selectedTimeFrame = [[timeFrameChoices objectAtIndex:0] objectForKey:@"value"];
}

- (void)updateCountriesData {
	NSMutableArray *countriesForChart = [NSMutableArray array];
	if (allCountries) {
		[allCountries enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
			NSDictionary *countryData = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"value", object, @"title", nil];
			[countryData addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:NULL];
			[countriesForChart addObject:countryData];
		}];
	}
	self.chartCountries = countriesForChart;
	self.chartImageView.image = nil;
}

- (void)updateTimeSpan {
	if ([selectedTimeFrame isKindOfClass:[NSNumber class]]) {
		self.fromDate = [NSDate dateWithTimeIntervalSinceNow:-[selectedTimeFrame doubleValue]];
		self.untilDate = [NSDate date];
	}
}

- (void)reloadChart {
	NSMutableArray *countries = [NSMutableArray array];
	for (NSDictionary *data in chartCountries) {
		if ([[data objectForKey:@"value"] boolValue]) {
			[countries addObject:[data objectForKey:@"title"]];
		}
	}
	if ([countries count] > 0) {
		NSError *error = nil;
		NSArray *entries = [[ARStorageManager sharedARStorageManager] rankEntriesForApplication:application 
																					 inCategory:category 
																					  countries:countries 
																						   from:self.fromDate
																						  until:self.untilDate
																						  error:&error];
		if (!entries) {
			[self presentError:error];
		} else {
			NSLog(@"Retrieved %d entries", [entries count]);
			if ([entries count] > 1) {
				ARChart *chart = [ARChart chartForEntries:entries sorted:YES];
				self.chartImageView.image = [chart image];
			} else {
				self.chartImageView.image = nil;
			}
		}
	} else {
		self.chartImageView.image = nil;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"allCountries"]) {
		[self updateCountriesData];
	} else if ([keyPath isEqualToString:@"selectedTimeFrame"]) {
		[self updateTimeSpan];
	} else {
		NSLog(@"Country selection has changed");
		[self reloadChart];
	}
}

#pragma mark -
#pragma mark NSTableViewDelegate

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSDictionary *data = [chartCountries objectAtIndex:row];
	NSString *country = [data objectForKey:@"title"];
	[cell setTitle:country];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[[ARColor colorForCountry:country] colorValue], NSForegroundColorAttributeName,
								[NSFont boldSystemFontOfSize:14.0], NSFontAttributeName, nil];
	NSAttributedString *altTitle = [[[NSAttributedString alloc] initWithString:country 
																	attributes:attributes] autorelease];
	[cell setAttributedAlternateTitle:altTitle];
}

- (BOOL)tableView:(NSTableView *)tableView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return YES;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
	return NO;
}

@end
