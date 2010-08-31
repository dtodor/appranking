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
#import "AppRankingAppDelegate.h"
#import "ARStorageManager.h"
#import "ARAppDetailsWindowController.h"


@interface ARMainViewController() <ARRankQueryDelegate>

@property (nonatomic, retain) NSMutableArray *runningQueries;
@property (nonatomic, retain) NSMutableArray *pendingQueries;
@property (nonatomic, retain) NSArray *applicationsTree;
@property (nonatomic, retain) ARAppDetailsWindowController *detailsViewController;

@end


@implementation ARMainViewController

@synthesize runningQueries;
@synthesize pendingQueries;
@synthesize applicationsTree;
@synthesize sidebar;
@synthesize statusToolBarItem;
@synthesize statusViewController;
@synthesize tableSortDescriptors;
@synthesize detailsViewController;
@synthesize treeController;
@synthesize outlineViewSortDescriptors;

- (void)dealloc {
	self.treeController = nil;
	self.detailsViewController = nil;
	self.tableSortDescriptors = nil;
	self.outlineViewSortDescriptors = nil;
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
	
	self.outlineViewSortDescriptors = [NSMutableArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	self.tableSortDescriptors = [NSMutableArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"rank" ascending:YES]];
}

- (void)reloadApplications {
	ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
	
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"ARCategoryTuple" inManagedObjectContext:storageManager.managedObjectContext]];
	
	NSError *error = nil;
	NSArray *categories = [storageManager.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	if (!categories) {
		NSLog(@"Unable to retrieve categories, error = %@", [error localizedDescription]);
		[self presentError:error];
		self.applicationsTree = nil;
		return;
	}
	
	NSMutableArray *array = [NSMutableArray array];
	for (ARCategoryTuple *category in categories) {
		ARTreeNode *node = [ARTreeNode treeNodeWithRepresentedObject:nil];
		node.category = category;
		node.name = [NSString stringWithFormat:@"%@ (%@)", 
					 [[category typeName] uppercaseString], 
					 (category.name?[category.name uppercaseString]:@"ALL")];
		for (ARApplication *application in category.applications) {
			ARTreeNode *child = [ARTreeNode treeNodeWithRepresentedObject:[NSMutableArray array]];
			child.application = application;
			child.name = application.name;
			child.icon = application.iconImage;
			[[node mutableChildNodes] addObject:child];
		}
		[array addObject:node];
	}
	self.applicationsTree = array;
	
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
		for (ARTreeNode *rootNode in self.applicationsTree) {
			ARRankQuery *query = [[ARRankQuery alloc] initWithCountry:country category:rootNode.category];
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

- (ARApplication *)selectedApplication {
	ARTreeNode *applicationNode = [[self.treeController selectedObjects] objectAtIndex:0];
	return applicationNode.application;
}

- (IBAction)info:(NSToolbarItem *)sender {
	self.detailsViewController = [[ARAppDetailsWindowController alloc] initWithWindowNibName:@"AppDetailsWindow"];
	self.detailsViewController.application = [self selectedApplication];
 	[NSApp beginSheet:[self.detailsViewController window] 
	   modalForWindow:[NSApp mainWindow] 
		modalDelegate:self 
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:NULL];
}

- (IBAction)addApplication:(NSButton *)sender {
	self.detailsViewController = [[ARAppDetailsWindowController alloc] initWithWindowNibName:@"AppDetailsWindow"];
 	[NSApp beginSheet:[self.detailsViewController window] 
	   modalForWindow:[NSApp mainWindow] 
		modalDelegate:self 
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	self.detailsViewController = nil;
	if (returnCode == DidSaveChanges) {
		[self reloadApplications];
	}
}

- (IBAction)sortByApplications:(NSMenuItem *)sender {
	NSLog(@"'sort by applications' action");
}

- (IBAction)sortByCategories:(NSMenuItem *)sender {
	NSLog(@"'sort by categories' action");
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
	for (NSString *appName in query.ranks) {
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
	
	for (NSString *appName in query.icons) {
		NSString *iconUrl = [query.icons objectForKey:appName];
		
		for (ARApplication *app in query.category.applications) {
			if ([app.name isEqualToString:appName] && !app.iconImage) {
				
				NSImage *icon = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:iconUrl]];
				if (icon) {
					app.iconImage = icon;
					[icon release];
					
					ARTreeNode *node = [self nodeForCategory:query.category application:appName];
					node.icon = icon;
					[sidebar reloadItem:nil];
				}
				
				break;
			}
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
		return [[sidebar selectedRowIndexes] count] == 1 && !self.runningQueries;
	}
	return NO;
}

@end
