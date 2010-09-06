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
#import "ARRankEntry.h"
#import "ARStorageManager+Testing.h"


@interface ARMainViewController() <ARRankQueryDelegate>

@property (nonatomic, retain) NSArray *applicationsTree;
@property (nonatomic, retain) NSMutableArray *runningQueries;
@property (nonatomic, retain) NSMutableArray *pendingQueries;
@property (nonatomic, retain) ARAppDetailsWindowController *detailsViewController;

@end


@implementation ARMainViewController

@synthesize applicationsTree;
@synthesize runningQueries;
@synthesize pendingQueries;
@synthesize sidebar;
@synthesize statusToolBarItem;
@synthesize statusViewController;
@synthesize tableSortDescriptors;
@synthesize detailsViewController;
@synthesize treeController;
@synthesize outlineViewSortDescriptors;
@synthesize chartViewController;
@synthesize mainContentSplitView;

- (void)dealloc {
	self.mainContentSplitView = nil;
	self.chartViewController = nil;
	self.applicationsTree = nil;
	self.treeController = nil;
	self.detailsViewController = nil;
	self.tableSortDescriptors = nil;
	self.outlineViewSortDescriptors = nil;
	self.statusViewController = nil;
	self.sidebar = nil;
	self.statusToolBarItem = nil;
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
	
	NSView *chartPlaceholder = [[mainContentSplitView subviews] objectAtIndex:1];
	[chartViewController.view setFrame:[chartPlaceholder bounds]];
	[chartPlaceholder addSubview:chartViewController.view];
	
	chartViewController.enabled = YES;
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
			NSMutableArray *representedObject = [storageManager testRanksForApplication:application inCategory:category];
			ARTreeNode *child = [ARTreeNode treeNodeWithRepresentedObject:representedObject];
			child.category = category;
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

- (void)resetRanks:(ARTreeNode *)node {
	NSMutableArray *ranks = [node representedObject];
	if (ranks) {
		NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [ranks count])];
		[node willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"representedObject"];
		[ranks removeAllObjects];
		[node didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"representedObject"];
	}
	for (ARTreeNode *child in [node childNodes]) {
		[self resetRanks:child];
	}
}

- (IBAction)refresh:(NSToolbarItem *)sender {
	if (self.runningQueries) {
		return;
	}
	
	chartViewController.enabled = NO;
	
	for (ARTreeNode *node in applicationsTree) {
		[self resetRanks:node];
	}
	
	[[ARStorageManager sharedARStorageManager] updateTimestamp];

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
				NSLog(@"Unable to start query for category '%@' and country '%@'", rootNode.category, country);
				// TODO log error message
			}
			count++;
		}
	}
	totalNumberOfDownloads = count;
}

- (void)updateUIOnFinish {
	[statusViewController.mainLabel setStringValue:@"Done"];
	[statusViewController.secondaryLabel setHidden:YES];
	[statusViewController setProgress:0.0];
	
	[NSApp setWindowsNeedUpdate:YES];
	
	chartViewController.enabled = YES;
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
	
	[self updateUIOnFinish];
	
	ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
	[storageManager.managedObjectContext rollback];
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
	   didEndSelector:@selector(editAppSheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:NULL];
}

- (IBAction)addApplication:(NSButton *)sender {
	self.detailsViewController = [[ARAppDetailsWindowController alloc] initWithWindowNibName:@"AppDetailsWindow"];
 	[NSApp beginSheet:[self.detailsViewController window] 
	   modalForWindow:[NSApp mainWindow] 
		modalDelegate:self 
	   didEndSelector:@selector(editAppSheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:NULL];
}

- (void)editAppSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	self.detailsViewController = nil;
	if (returnCode == DidSaveChanges) {
		[[ARStorageManager sharedARStorageManager] tryDeletingUnusedCategories];
		[self reloadApplications];
	}
}

- (IBAction)removeApplication:(NSButton *)sender {
	ARApplication *application = [self selectedApplication];
	NSAlert *alert = [NSAlert alertWithMessageText:@"Delete Confirmation" 
									 defaultButton:@"Yes" 
								   alternateButton:@"No" 
									   otherButton:nil 
						 informativeTextWithFormat:@"Are you sure you want to delete the application '%@'?", application.name];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert beginSheetModalForWindow:[[self view] window] 
					  modalDelegate:self 
					 didEndSelector:@selector(deleteConfirmationSheetDidEnd:returnCode:contextInfo:) 
						contextInfo:NULL];
}

- (void)deleteConfirmationSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertDefaultReturn) {
		ARApplication *application = [self selectedApplication];
		NSManagedObjectContext *managedObjectContext = [ARStorageManager sharedARStorageManager].managedObjectContext;
		[managedObjectContext deleteObject:application];
		NSError *error = nil;
		if (![managedObjectContext save:&error]) {
			[self presentError:error];
		} else {
			[[ARStorageManager sharedARStorageManager] tryDeletingUnusedCategories];
			[self reloadApplications];
		}
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
	if ([pendingQueries count] > 0) {
		ARRankQuery *query = [[pendingQueries lastObject] retain];
		[pendingQueries removeLastObject];
		[runningQueries addObject:[query autorelease]];
		[query start];
	}
	if ([runningQueries count] == 0) {
		// Finished
		self.runningQueries = nil;
		self.pendingQueries = nil;

		[self updateUIOnFinish];

		ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
		NSError *error = nil;
		if (![storageManager.managedObjectContext save:&error]) {
			[self presentError:error];
		}
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
			NSLog(@"[ARRankQuery] %@ (%@) - %d", query.country, query.category, [value intValue]);
			ARTreeNode *applicationNode = [self nodeForCategory:query.category application:appName];
			assert(applicationNode);
			NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:value, @"rank", query.country, @"country", nil];
			NSMutableArray *entries = [applicationNode representedObject];
			[applicationNode willChange:NSKeyValueChangeInsertion 
						valuesAtIndexes:[NSIndexSet indexSetWithIndex:[entries count]] 
								 forKey:@"representedObject"];
			
			[entries addObject:entry];
			
			[applicationNode didChange:NSKeyValueChangeInsertion 
					   valuesAtIndexes:[NSIndexSet indexSetWithIndex:[entries count]-1] 
								forKey:@"representedObject"];

			NSError *error = nil;
			if (![[ARStorageManager sharedARStorageManager] insertRankEntry:value forApplication:applicationNode.application query:query error:&error]) {
				NSLog(@"Unable to persist result for '%@ - %@ (%@)'", applicationNode.application.name, query.country, query.category);
			}
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

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	NSArray *selectedObjects = [self.treeController selectedObjects];
	if ([selectedObjects count] == 1) {
		ARTreeNode *selection = [selectedObjects objectAtIndex:0];
		NSError *error = nil;
		NSArray *countries = [[ARStorageManager sharedARStorageManager] rankedCountriesForApplication:selection.application 
																	  inCategory:selection.category 
																		   error:&error];
		if (!countries) {
			[self presentError:error];
		} else {
			chartViewController.application = selection.application;
			chartViewController.category = selection.category;
			chartViewController.allCountries = countries;
		}
	}
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
