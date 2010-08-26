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

#import "ARMainViewController.h"
#import "ARConfiguration.h"
#import "ARRankQuery.h"
#import "ARCategoryTuple.h"
#import "ARTreeNode.h"
#import "ARApplication.h"
#import "SidebarBadgeCell.h"
#import "ARStatusView.h"


@interface ARMainViewController() <ARRankQueryDelegate>

@property (retain) NSMutableArray *runningQueries;
@property (retain) NSMutableArray *pendingQueries;
@property (retain) NSArray *applicationsTree;

@end


@implementation ARMainViewController

@synthesize runningQueries;
@synthesize pendingQueries;
@synthesize applicationsTree;
@synthesize sidebar;
@synthesize statusToolBarItem;
@synthesize statusViewController;
@synthesize treeSelection;
@synthesize tableSortDescriptors;

- (void)dealloc {
	self.tableSortDescriptors = nil;
	self.treeSelection = nil;
	self.statusViewController = nil;
	self.sidebar = nil;
	self.statusToolBarItem = nil;
	self.applicationsTree = nil;
	self.runningQueries = nil;
	self.pendingQueries = nil;
	[super dealloc];
}

- (void)awakeFromNib {
	[statusToolBarItem setView:[statusViewController view]];
	[statusViewController.mainLabel setStringValue:@"Welcome"];
	[statusViewController.secondaryLabel setHidden:YES];
	[statusViewController setProgress:0.0];
}

- (void)reloadApplications {
	NSDictionary *appsDict = [ARConfiguration sharedARConfiguration].applications;
	NSMutableArray *array = [NSMutableArray array];
	for (ARCategoryTuple *category in appsDict) {
		ARTreeNode *node = [ARTreeNode treeNodeWithRepresentedObject:nil];
		node.category = category;
		node.name = [NSString stringWithFormat:@"%@ (%@)", 
					 [[category typeName] uppercaseString], 
					 (category.name?[category.name uppercaseString]:@"ALL")];
		NSArray *applications = [appsDict objectForKey:category];
		for (ARApplication *application in applications) {
			ARTreeNode *child = [ARTreeNode treeNodeWithRepresentedObject:[NSMutableArray array]];
			child.name = application.name;
			[[node mutableChildNodes] addObject:child];
		}
		[array addObject:node];
	}
	self.tableSortDescriptors = [NSMutableArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"rank" ascending:YES]];
	self.applicationsTree = array;
	self.treeSelection = [NSMutableArray array];
	
	[sidebar expandItem:nil expandChildren:YES];
}

#pragma mark -
#pragma mark IBAction methods

- (IBAction)refresh:(NSToolbarItem *)sender {
	if (self.runningQueries) {
		return;
	}
	[statusViewController.mainLabel setStringValue:@"Processing RSS feeds ..."];
	[statusViewController.secondaryLabel setStringValue:@""];
	[statusViewController.secondaryLabel setHidden:NO];

	self.runningQueries = [NSMutableArray array];
	self.pendingQueries = [NSMutableArray array];
	
	static NSUInteger maxConcurrent = 20;
	
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
	totalNumberOfDownloads = count;
}

- (IBAction)stop:(NSToolbarItem *)sender {
	for (ARRankQuery *query in runningQueries) {
		[query cancel];
	}
	for (ARRankQuery *query in pendingQueries) {
		[query cancel];
	}
	self.runningQueries = nil;
	self.pendingQueries = nil;
	
	[statusViewController.mainLabel setStringValue:@"Done"];
	[statusViewController.secondaryLabel setHidden:YES];
	[statusViewController setProgress:0.0];
}

- (IBAction)info:(NSToolbarItem *)sender {
}

#pragma mark -
#pragma mark ARRankQueryDelegate

- (void)processQuery:(ARRankQuery *)query {
	[runningQueries removeObject:query];
	NSUInteger count = [runningQueries count] + [pendingQueries count];
	double percent = ((double)totalNumberOfDownloads-count)/totalNumberOfDownloads;
	[statusViewController setProgress:percent];
	if ([runningQueries count] == 0) {
		self.runningQueries = nil;
		self.pendingQueries = nil;
		[statusViewController.mainLabel setStringValue:@"Done"];
		[statusViewController.secondaryLabel setHidden:YES];
		[statusViewController setProgress:0.0];
	}
	if ([pendingQueries count] > 0) {
		ARRankQuery *query = [pendingQueries lastObject];
		[pendingQueries removeLastObject];
		[runningQueries addObject:query];
		[query start];
	}
}

- (ARTreeNode *)nodeForCategory:(ARCategoryTuple *)category application:(NSString *)app {
	for (ARTreeNode *rootNode in applicationsTree) {
		if (rootNode.category == category) {
			NSArray *children = [rootNode childNodes];
			for (ARTreeNode *child in children) {
				if ([child.name isEqualToString:app]) {
					return child;
				}
			}
		}
	}
	return nil;
}

- (void)queryDidFinish:(ARRankQuery *)query {
	[statusViewController.secondaryLabel setStringValue:[NSString stringWithFormat:@"Finished processing %@ [%@]", query.country, query.category]];
	NSEnumerator *appNames = [query.ranks keyEnumerator];
	NSString *appName = nil;
	while (appName = [appNames nextObject]) {
		id value = [query.ranks objectForKey:appName];
		if ([value isKindOfClass:[NSNumber class]]) {
			ARTreeNode *node = [self nodeForCategory:query.category application:appName];
			if (node) {
				NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:value, @"rank", query.country, @"country", nil];
				NSMutableArray *entries = [node representedObject];
				[node willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:[entries count]] forKey:@"representedObject"];
				[entries addObject:entry];
				[node didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:[entries count]-1] forKey:@"representedObject"];
			}
			NSLog(@"[ARRankQuery] %@ (%@) - %d", query.country, query.category, [value intValue]);
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

#pragma mark -
#pragma mark NSOutlineViewDelegate

- (void)outlineView:(NSOutlineView *)outlineView
    willDisplayCell:(NSCell*)cell
     forTableColumn:(NSTableColumn *)tableColumn
               item:(id)item {
	
	if ([cell isKindOfClass:[SidebarBadgeCell class]]) {
		SidebarBadgeCell *badgeCell = (SidebarBadgeCell *)cell;
		ARTreeNode *node = [(NSTreeNode *)item representedObject];
		[badgeCell setBadgeCount:node.badge];
		[badgeCell setHasBadge:node.displaysBadge];
		[badgeCell setIcon:node.icon];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView_ isGroupItem:(id)item {
	return [outlineView_ parentForItem:item] == nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView_ shouldSelectItem:(id)item {
	return [outlineView_ parentForItem:item] != nil;
}

#pragma mark -
#pragma mark NSToolbarItemValidation

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	if ([[theItem itemIdentifier] isEqualToString:@"RefreshToolbarItem"]) {
		return self.runningQueries == nil;
	} else if ([[theItem itemIdentifier] isEqualToString:@"StopToolbarItem"]) {
		return self.runningQueries != nil;
	} else if ([[theItem itemIdentifier] isEqualToString:@"InfoToolbarItem"]) {
		return [[sidebar selectedRowIndexes] count] == 1;
	}
	return NO;
}

@end
