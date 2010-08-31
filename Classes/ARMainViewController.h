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

#import <Cocoa/Cocoa.h>
#import "ARStatusViewController.h"
#import "ARAppDetailsWindowController.h"


@interface ARMainViewController : NSViewController <NSOutlineViewDelegate> {

	NSUInteger totalNumberOfDownloads;
	NSMutableArray *runningQueries;
	NSMutableArray *pendingQueries;
	NSMutableArray *applicationsTree;
	NSMutableArray *treeSelection;
	NSMutableArray *tableSortDescriptors;
	NSMutableArray *outlineViewSortDescriptors;
	
	NSOutlineView *sidebar;
	NSToolbarItem *statusToolBarItem;
	ARStatusViewController *statusViewController;
	ARAppDetailsWindowController *detailsViewController;
	
	NSTreeController *treeController;
}

@property (nonatomic, readonly, retain) NSArray *applicationsTree;
@property (nonatomic, retain) NSMutableArray *tableSortDescriptors;
@property (nonatomic, retain) NSMutableArray *outlineViewSortDescriptors;
@property (nonatomic, retain) IBOutlet NSOutlineView *sidebar;
@property (nonatomic, retain) IBOutlet NSToolbarItem *statusToolBarItem;
@property (nonatomic, retain) IBOutlet ARStatusViewController *statusViewController;
@property (nonatomic, retain) IBOutlet NSTreeController *treeController;

- (void)reloadApplications;
- (IBAction)refresh:(NSToolbarItem *)sender;
- (IBAction)stop:(NSToolbarItem *)sender;
- (IBAction)info:(NSToolbarItem *)sender;

- (IBAction)addApplication:(NSButton *)sender;
- (IBAction)sortByApplications:(NSMenuItem *)sender;
- (IBAction)sortByCategories:(NSMenuItem *)sender;

@end
