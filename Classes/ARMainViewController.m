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


@interface ARMainViewController() <RankQueryDelegate>

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

- (void)dealloc {
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
}

- (void)reloadApplications {
	NSDictionary *appsDict = [ARConfiguration sharedARConfiguration].applications;
	NSMutableArray *array = [NSMutableArray array];
	for (ARCategoryTuple *category in appsDict) {
		ARTreeNode *node = [[ARTreeNode alloc] init];
		node.name = [NSString stringWithFormat:@"%@ (%@)", 
					 [[category typeName] uppercaseString], 
					 (category.name?[category.name uppercaseString]:@"ALL")];
		NSArray *applications = [appsDict objectForKey:category];
		for (ARApplication *application in applications) {
			ARTreeNode *child = [[ARTreeNode alloc] init];
			child.name = application.name;
			[node addChild:child];
			[child release];
		}
		[array addObject:node];
		[node release];
	}
	self.applicationsTree = array;
	
	[sidebar expandItem:nil expandChildren:YES];
}

- (IBAction)start:(id)sender {
	[sender setEnabled:NO];
	
	self.runningQueries = [NSMutableArray array];
	self.pendingQueries = [NSMutableArray array];
	
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
		self.runningQueries = nil;
		self.pendingQueries = nil;
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
	return NO;
}

@end
