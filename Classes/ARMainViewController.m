/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
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
#import "ARRSSFeedCache.h"

#import <Growl/Growl.h>


@interface ARMainViewController() <ARRankQueryDelegate, GrowlApplicationBridgeDelegate>

@property (nonatomic, strong) NSArray *applicationsTree;
@property (nonatomic, strong) NSMutableArray *runningQueries;
@property (nonatomic, strong) NSMutableArray *pendingQueries;
@property (nonatomic, strong) ARAppDetailsWindowController *detailsViewController;
@property (nonatomic) NSUInteger totalNumberOfDownloads;

- (IBAction)emptyCache:(id)sender;
@property (weak) IBOutlet NSMenuItem *emptyCacheMenuItem;

@property (nonatomic, strong) NSMutableArray *tableSortDescriptors;
@property (nonatomic, strong) NSMutableArray *outlineViewSortDescriptors;
@property (nonatomic, weak) IBOutlet NSOutlineView *sidebar;
@property (nonatomic, weak) IBOutlet NSToolbarItem *statusToolBarItem;
@property (nonatomic, assign) IBOutlet ARStatusViewController *statusViewController;
@property (nonatomic, weak) IBOutlet NSTreeController *treeController;
@property (nonatomic, assign) IBOutlet ARChartViewController *chartViewController;
@property (nonatomic, weak) IBOutlet NSSplitView *mainContentSplitView;

- (IBAction)refresh:(NSToolbarItem *)sender;
- (IBAction)stop:(NSToolbarItem *)sender;
- (IBAction)info:(NSToolbarItem *)sender;

- (IBAction)addApplication:(NSButton *)sender;
- (IBAction)removeApplication:(NSButton *)sender;

@end


@implementation ARMainViewController

@synthesize emptyCacheMenuItem = _emptyCacheMenuItem;
@synthesize applicationsTree = _applicationsTree;
@synthesize runningQueries = _runningQueries;
@synthesize pendingQueries = _pendingQueries;
@synthesize sidebar = _sidebar;
@synthesize statusToolBarItem = _statusToolBarItem;
@synthesize statusViewController = _statusViewController;
@synthesize tableSortDescriptors = _tableSortDescriptors;
@synthesize detailsViewController = _detailsViewController;
@synthesize treeController = _treeController;
@synthesize outlineViewSortDescriptors = _outlineViewSortDescriptors;
@synthesize chartViewController = _chartViewController;
@synthesize mainContentSplitView = _mainContentSplitView;
@synthesize totalNumberOfDownloads = _totalNumberOfDownloads;

#pragma mark -
#pragma mark Lifecycle

- (void)awakeFromNib 
{
	[self.statusToolBarItem setView:[self.statusViewController view]];
	[self.statusViewController.mainLabel setStringValue:@"Welcome"];
	[self.statusViewController.secondaryLabel setHidden:YES];
	[self.statusViewController setProgress:0.0];
	
	self.outlineViewSortDescriptors = [NSMutableArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
	self.tableSortDescriptors = [NSMutableArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"rank" ascending:YES]];
	
	NSView *chartPlaceholder = [[self.mainContentSplitView subviews] objectAtIndex:1];
	[self.chartViewController.view setFrame:[chartPlaceholder bounds]];
	[chartPlaceholder addSubview:self.chartViewController.view];
	
	self.chartViewController.enabled = YES;
	
	[GrowlApplicationBridge setGrowlDelegate:self];
	
	[self.sidebar setDoubleAction:@selector(doubleAction:)];
	[self.sidebar setTarget:self];
}

#pragma mark -
#pragma mark Private helper methods

- (void)displayInfoForApplication:(ARApplication *)app 
{
	if (self.detailsViewController) {
		return;
	}
	self.detailsViewController = [[ARAppDetailsWindowController alloc] initWithWindowNibName:@"AppDetailsWindow"];
	self.detailsViewController.application = app;
 	[NSApp beginSheet:[self.detailsViewController window] 
	   modalForWindow:[NSApp mainWindow] 
		modalDelegate:self 
	   didEndSelector:@selector(editAppSheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:NULL];
}

- (void)doubleAction:(NSOutlineView *)sender 
{
	if (self.runningQueries) {
		return;
	}
	ARTreeNode *item = [[sender itemAtRow:[sender clickedRow]] representedObject];
	if (item.application) {
		[self displayInfoForApplication:item.application];
	}
}

- (void)updateChartCountries 
{
	NSArray *selectedObjects = [self.treeController selectedObjects];
	if ([selectedObjects count] == 1) {
		ARTreeNode *selection = [selectedObjects objectAtIndex:0];
		self.chartViewController.application = selection.application;
		self.chartViewController.category = selection.category;
		NSError *error = nil;
		NSArray *countries = [[ARStorageManager sharedARStorageManager] rankedCountriesForApplication:selection.application 
																						   inCategory:selection.category 
																								error:&error];
		if (!countries) {
			self.chartViewController.allCountries = nil;
			[self presentError:error];
		} else {
			self.chartViewController.allCountries = countries;
		}
	}
}

- (void)updateUIOnFinish 
{
	[self.statusViewController.mainLabel setStringValue:@"Done"];
	[self.statusViewController.secondaryLabel setHidden:YES];
	[self.statusViewController setProgress:0.0];
    [self.emptyCacheMenuItem.menu setAutoenablesItems:YES];
    [self.emptyCacheMenuItem setEnabled:YES];
	
	[NSApp setWindowsNeedUpdate:YES];
	
	[self updateChartCountries];
	self.chartViewController.enabled = YES;
}

- (ARApplication *)selectedApplication 
{
	ARTreeNode *applicationNode = [[self.treeController selectedObjects] objectAtIndex:0];
	return applicationNode.application;
}

- (void)postFinishNotifications 
{
	[GrowlApplicationBridge notifyWithTitle:@"Finished updating ranks" 
								description:@"AppRanking has finished updating the ranks for your applications. To review the results, select an application from the categories and applications list on the left." 
						   notificationName:@"ARRefreshFinishedNotification" 
								   iconData:nil 
								   priority:0 
								   isSticky:NO 
							   clickContext:nil];
}

#pragma mark -
#pragma mark IBAction methods

- (IBAction)emptyCache:(id)sender 
{
	NSAlert *alert = [NSAlert alertWithMessageText:@"Empty Cache" 
									 defaultButton:@"Empty" 
								   alternateButton:@"Cancel" 
									   otherButton:nil 
						 informativeTextWithFormat:@"Are you sure you want to empty the cache?"];
	[alert setAlertStyle:NSInformationalAlertStyle];
    NSInteger returnCode = [alert runModal];
	if (returnCode == NSAlertDefaultReturn) {
        [[ARRSSFeedCache sharedARRSSFeedCache] emptyCache];
    }
}

- (void)resetRanks:(ARTreeNode *)node 
{
	NSMutableArray *ranks = [node representedObject];
	if (ranks) {
		NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [ranks count])];
		[node willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"representedObject"];
		[ranks removeAllObjects];
		[node didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"representedObject"];
	}
	node.badge = 0;
	node.displaysBadge = NO;
	for (ARTreeNode *child in [node childNodes]) {
		[self resetRanks:child];
	}
}

- (IBAction)refresh:(NSToolbarItem *)sender 
{
	if (self.runningQueries) {
		return;
	}
	
	[self.statusViewController.mainLabel setStringValue:@"Processing RSS feeds ..."];
	[self.statusViewController.secondaryLabel setStringValue:@""];
	[self.statusViewController.secondaryLabel setHidden:NO];
    [self.emptyCacheMenuItem.menu setAutoenablesItems:NO];
    [self.emptyCacheMenuItem setEnabled:NO];
	[self.statusViewController displayIndeterminateProgress];
	
	self.chartViewController.enabled = NO;
	
	for (ARTreeNode *node in self.applicationsTree) {
		[self resetRanks:node];
	}
	
	[[ARStorageManager sharedARStorageManager] updateTimestamp];

	self.runningQueries = [NSMutableArray array];
	self.pendingQueries = [NSMutableArray array];
	
	static NSUInteger maxConcurrent = 20;

	ARConfiguration *config = [ARConfiguration sharedARConfiguration];

	NSUInteger count = 0;
	for (NSString *country in config.countries) {
		for (ARTreeNode *rootNode in self.applicationsTree) {
			count++;
			ARRankQuery *query = [[ARRankQuery alloc] initWithCountry:country category:rootNode.category];
			if (query) {
				query.delegate = self;
				if (count < maxConcurrent) {
					[self.runningQueries addObject:query];
					[query start];
				} else {
					[self.pendingQueries addObject:query];
				}
			} else {
				NSLog(@"Unable to start query for category '%@' and country '%@'", rootNode.category, country);
			}
		}
	}
	self.totalNumberOfDownloads = count;
}

- (IBAction)stop:(NSToolbarItem *)sender 
{
	for (ARRankQuery *query in self.runningQueries) {
		[query cancel];
	}
	for (ARRankQuery *query in self.pendingQueries) {
		[query cancel];
	}
	self.runningQueries = nil;
	self.pendingQueries = nil;
	
	[self updateUIOnFinish];
	
	ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
	[storageManager.managedObjectContext rollback];
}

- (IBAction)info:(NSToolbarItem *)sender 
{
	[self displayInfoForApplication:[self selectedApplication]];
}

- (IBAction)addApplication:(NSButton *)sender 
{
	self.detailsViewController = [[ARAppDetailsWindowController alloc] initWithWindowNibName:@"AppDetailsWindow"];
	self.detailsViewController.application = nil;
 	[NSApp beginSheet:[self.detailsViewController window] 
	   modalForWindow:[NSApp mainWindow] 
		modalDelegate:self 
	   didEndSelector:@selector(editAppSheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:NULL];
}

- (void)editAppSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo 
{
	self.detailsViewController = nil;
	if (returnCode == DidSaveChanges) {
		[[ARStorageManager sharedARStorageManager] tryDeletingUnusedCategories];
		[self reloadApplications];
	}
}

- (IBAction)removeApplication:(NSButton *)sender 
{
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

- (void)deleteConfirmationSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo 
{
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
	 
#pragma mark -
#pragma mark ARRankQueryDelegate

- (void)processQuery:(ARRankQuery *)query 
{
	[self.runningQueries removeObject:query];
	NSUInteger count = [self.runningQueries count] + [self.pendingQueries count];
	double percent = ((double)self.totalNumberOfDownloads-count)/self.totalNumberOfDownloads;
	[self.statusViewController setProgress:percent];
	if ([self.pendingQueries count] > 0) {
		ARRankQuery *query = [self.pendingQueries lastObject];
		[self.pendingQueries removeLastObject];
		[self.runningQueries addObject:query];
		[query start];
	}
	if ([self.runningQueries count] == 0) {
		// Finished
		self.runningQueries = nil;
		self.pendingQueries = nil;

		[self updateUIOnFinish];

		ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
		NSError *error = nil;
		if (![storageManager.managedObjectContext save:&error]) {
			[self presentError:error];
		}
		
		[self postFinishNotifications];
	}
}

- (ARTreeNode *)nodeForCategory:(ARCategoryTuple *)category application:(NSString *)app 
{
	for (ARTreeNode *rootNode in self.applicationsTree) {
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

- (void)queryDidFinish:(ARRankQuery *)query 
{
	if (self.runningQueries == nil) {
		return;
	}
	[self.statusViewController.secondaryLabel setStringValue:[NSString stringWithFormat:@"Finished processing %@ [%@]", query.country, query.category]];
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
			
			applicationNode.badge = [entries count];
			applicationNode.displaysBadge = YES;
			[self.sidebar reloadItem:nil];

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
					
					ARTreeNode *node = [self nodeForCategory:query.category application:appName];
					node.icon = icon;
					[self.sidebar reloadItem:nil];
				}
				
				break;
			}
		}
	}

	[self processQuery:query];
}

- (void)query:(ARRankQuery *)query didFailWithError:(NSError *)error 
{
//	NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
//	NSString *message = [NSString stringWithFormat:@"%@ - %@ failed (error: %@)\n", 
//						 query.country, query.category, [error localizedDescription]];
//	NSAttributedString *text = [[NSAttributedString alloc] initWithString:message attributes:attributes];
	[self processQuery:query];
}

#pragma mark -
#pragma mark NSOutlineViewDelegate

- (void)outlineView:(NSOutlineView *)outlineView
    willDisplayCell:(NSCell *)cell
     forTableColumn:(NSTableColumn *)tableColumn
               item:(id)item 
{
	
	if ([cell isKindOfClass:[SidebarBadgeCell class]]) {
		SidebarBadgeCell *badgeCell = (SidebarBadgeCell *)cell;
		ARTreeNode *node = [(NSTreeNode *)item representedObject];
		[badgeCell setBadgeCount:node.badge];
		[badgeCell setHasBadge:node.displaysBadge];
		[badgeCell setIcon:node.icon];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView_ isGroupItem:(id)item 
{
	return [outlineView_ parentForItem:item] == nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView_ shouldSelectItem:(id)item 
{
	return [outlineView_ parentForItem:item] != nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification 
{
	[self updateChartCountries];
}

#pragma mark -
#pragma mark NSToolbarItemValidation

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem 
{
	if ([[theItem itemIdentifier] isEqualToString:@"RefreshToolbarItem"]) {
		return self.runningQueries == nil;
	} else if ([[theItem itemIdentifier] isEqualToString:@"StopToolbarItem"]) {
		return self.runningQueries != nil;
	} else if ([[theItem itemIdentifier] isEqualToString:@"InfoToolbarItem"]) {
		return [[self.sidebar selectedRowIndexes] count] == 1 && !self.runningQueries;
	}
	return NO;
}

#pragma mark -
#pragma mark NSTableViewDelegate

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row 
{
	if ([[tableColumn identifier] isEqualToString:@"NumberColumn"]) {
		[cell setStringValue:[NSString stringWithFormat:@"%d", row+1]];
	}
}

#pragma mark -
#pragma mark Public interface

- (void)reloadApplications 
{
	ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
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
	
	[self.sidebar expandItem:nil expandChildren:YES];
	NSUInteger indexes[] = { 0, 0 };
	[self.treeController setSelectionIndexPath:[NSIndexPath indexPathWithIndexes:indexes length:2]];
}

#pragma mark -
#pragma mark NSSplitViewDelegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex 
{
    
    NSSize size = [splitView bounds].size;
    if (splitView.isVertical) {
#define kMinLeft 200.0
#define kMinRight 300.0
        
        if (proposedPosition < kMinLeft) {
            return kMinLeft;
        } else if (proposedPosition > size.width-kMinRight) {
            return size.width-kMinRight;
        }
        
    } else {
#define kMinTop 200.0
#define kMinBottom 200.0
        
        if (proposedPosition < kMinTop) {
            return kMinTop;
        } else if (proposedPosition > size.height-kMinBottom) {
            return size.height-kMinBottom;
        }
        
    }
    
    return proposedPosition;
}

@end
