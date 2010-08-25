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

#import "AppRankingAppDelegate.h"
#import "ARConfiguration.h"
#import "ARRankQuery.h"
#import "ARCategoryTuple.h"


@implementation AppRankingAppDelegate

@synthesize window;
@synthesize mainViewController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSError *error = nil;
	if (![[ARConfiguration sharedARConfiguration] loadConfiguration:&error]) {
		[window presentError:error];
	}
	NSView *mainView = [mainViewController view];
	NSView *contentView = [window contentView];
	CGRect frame = [contentView frame];
	[mainView setFrame:frame];
	[[window contentView] addSubview:mainView];
}

- (void)dealloc {
	[runningQueries release];
	[pendingQueries release];
	[super dealloc];
}

- (IBAction)start:(NSButton *)sender {
	[sender setEnabled:NO];
	
	runningQueries = [[NSMutableArray alloc] init];
	pendingQueries = [[NSMutableArray alloc] init];
	
	static NSUInteger maxConcurrent = 30;
	
	NSUInteger count = 0;
	ARConfiguration *config = [ARConfiguration sharedARConfiguration];
	for (NSString *country in config.appStoreIds) {
		for (ARCategoryTuple *tuple in config.applications) {
			ARRankQuery *query = [[ARRankQuery alloc] initWithCountry:country category:tuple applications:[config.applications objectForKey:tuple]];
			if (query) {
				query.delegate = self;
				if (count < maxConcurrent) {
					[runningQueries addObject:query];
					[query start];
				} else {
					[pendingQueries addObject:query];
				}
				[query release];
			} else {
				// TODO log error message
			}
			count++;
		}
	}
}

- (void)processQuery:(ARRankQuery *)query {
	[runningQueries removeObject:query];
	if ([runningQueries count] == 0) {
		[runningQueries release];
		runningQueries = nil;
		[pendingQueries release];
		pendingQueries = nil;
	}
	if ([pendingQueries count] > 0) {
		ARRankQuery *query = [pendingQueries lastObject];
		[pendingQueries removeLastObject];
		[runningQueries addObject:query];
		[query start];
	}
}

- (void)queryDidFinish:(ARRankQuery *)query {
	NSEnumerator *appNames = [query.ranks keyEnumerator];
	NSString *appName = nil;
	while (appName = [appNames nextObject]) {
		id value = [query.ranks objectForKey:appName];
		if ([value isKindOfClass:[NSNumber class]]) {
			// TODO Process rank
		}
	}
	[self processQuery:query];
}

- (void)query:(ARRankQuery *)query didFailWithError:(NSError *)error {
	NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
	NSString *message = [NSString stringWithFormat:@"%@ - %@ failed (error: %@)\n", 
						 query.country, query.category, [error localizedDescription]];
	NSAttributedString *text = [[NSAttributedString alloc] initWithString:message attributes:attributes];
	// TODO log error message
	[text release];
	[self processQuery:query];
}

@end
