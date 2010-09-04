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
#import "ARStorageManager.h"
#import "ARCategoryTuple.h"
#import "ARApplication.h"
#import "AREnumValueTransformer.h"
#import "ARRankEntry.h"
#import "ARStorageManager+Testing.h"
#import "ARBoolValueTransformer.h"


@implementation AppRankingAppDelegate

@synthesize window;
@synthesize mainViewController;

+ (void)initialize {
	if (self == [AppRankingAppDelegate class]) {
		{
			AREnumValueTransformer *categoryTypesTransformer = [[AREnumValueTransformer alloc] initWithValueNames:[ARCategoryTuple typeNames]];
			[NSValueTransformer setValueTransformer:categoryTypesTransformer forName:@"ARCategoryTupleTypeValueTransformer"];
			[categoryTypesTransformer release];
		}
		
		EvalBlock isNilOrNSNull = ^(id value) {
			if (!value) {
				return YES;
			}
			if ([value isKindOfClass:[NSNull class]]) {
				return YES;
			}
			return NO;
		};
		
		{
			ARBoolValueTransformer *isNilTransformer = [[ARBoolValueTransformer alloc] initWithEvaluationBlock:isNilOrNSNull];
			[NSValueTransformer setValueTransformer:isNilTransformer forName:@"ARIsNilOrNSNull"];
			[isNilTransformer release];
		}

		{
			ARBoolValueTransformer *isNotNilTransformer = [[ARBoolValueTransformer alloc] initWithEvaluationBlock:^(id value) {
				return (BOOL)!isNilOrNSNull(value);
			}];
			[NSValueTransformer setValueTransformer:isNotNilTransformer forName:@"ARIsNotNilOrNSNull"];
			[isNotNilTransformer release];
		}
	}
}

- (void)dealloc {
	self.mainViewController = nil;
    [window release];
    [super dealloc];
}

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
	
	
	{
		ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
		[storageManager resetTestData];
		[storageManager generateRandomRankingsDeletingExistent:YES];
	}
	
	[mainViewController reloadApplications];
}

/**
 Implementation of the applicationShouldTerminate: method, used here to
 handle the saving of changes in the application managed object context
 before the application terminates.
 */
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    NSError *error = nil;
	if (![[ARStorageManager sharedARStorageManager] commitChanges:&error]) {
		
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.
		
        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
		
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;
		
        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
		
        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
    }
    return NSTerminateNow;
}

@end
