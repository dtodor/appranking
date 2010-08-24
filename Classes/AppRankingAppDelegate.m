//
//  AppRankingAppDelegate.m
//  AppRanking
//
//  Created by Todor Dimitrov on 22.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import "AppRankingAppDelegate.h"
#import "ARConfiguration.h"
#import "ARRankQuery.h"
#import "ARCategoryTuple.h"


@implementation AppRankingAppDelegate

@synthesize window;
@synthesize logTextView;
@synthesize startButton;
@synthesize progressIndicator;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSError *error = nil;
	if (![[ARConfiguration sharedARConfiguration] loadConfiguration:&error]) {
		[window presentError:error];
	}
	[progressIndicator setHidden:YES];
}

- (void)dealloc {
	[runningQueries release];
	[pendingQueries release];
	self.progressIndicator = nil;
	self.startButton = nil;
	self.logTextView = nil;
	self.window = nil;
	[super dealloc];
}

- (IBAction)start:(NSButton *)sender {
	[sender setEnabled:NO];
	
	[progressIndicator setHidden:NO];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator setMinValue:0.0];

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
				[self.logTextView insertText:[NSString stringWithFormat:@"%@ - %@ failed.\n", country, tuple]];
			}
			count++;
		}
	}
	
	[progressIndicator setMaxValue:count];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setDoubleValue:0.0];
}

- (void)processQuery:(ARRankQuery *)query {
	[progressIndicator setDoubleValue:[progressIndicator doubleValue]+1];
	[runningQueries removeObject:query];
	if ([runningQueries count] == 0) {
		[runningQueries release];
		runningQueries = nil;
		[pendingQueries release];
		pendingQueries = nil;
		
		[self.startButton setEnabled:YES];
		[progressIndicator setHidden:YES];
		[progressIndicator setIndeterminate:YES];
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
			[self.logTextView insertText:[NSString stringWithFormat:@"[%@] %@ - %d\n", 
										  appName, query.country, [(NSNumber *)value integerValue]]];
		}
	}
	[self processQuery:query];
}

- (void)query:(ARRankQuery *)query didFailWithError:(NSError *)error {
	NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
	NSString *message = [NSString stringWithFormat:@"%@ - %@ failed (error: %@)\n", 
						 query.country, query.category, [error localizedDescription]];
	NSAttributedString *text = [[NSAttributedString alloc] initWithString:message attributes:attributes];
	[self.logTextView insertText:text];
	[text release];
	[self processQuery:query];
}

@end
