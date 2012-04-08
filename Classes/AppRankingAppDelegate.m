/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
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

@synthesize window = _window;
@synthesize mainViewController = _mainViewController;

+ (void)initialize 
{
	if (self == [AppRankingAppDelegate class]) {
		{
			AREnumValueTransformer *categoryTypesTransformer = [[AREnumValueTransformer alloc] initWithValueNames:[ARCategoryTuple typeNames]];
			[NSValueTransformer setValueTransformer:categoryTypesTransformer forName:@"ARCategoryTupleTypeValueTransformer"];
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
		}

		{
			ARBoolValueTransformer *isNotNilTransformer = [[ARBoolValueTransformer alloc] initWithEvaluationBlock:^(id value) {
				return (BOOL)!isNilOrNSNull(value);
			}];
			[NSValueTransformer setValueTransformer:isNotNilTransformer forName:@"ARIsNotNilOrNSNull"];
		}
	}
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application 
{
	return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	NSError *error = nil;
	if (![[ARConfiguration sharedARConfiguration] loadConfiguration:&error]) {
		[self.window presentError:error];
	}
	NSView *mainView = [self.mainViewController view];
	NSView *contentView = [self.window contentView];
	CGRect frame = [contentView frame];
	[mainView setFrame:frame];
	[[self.window contentView] addSubview:mainView];
	
	
	{
		//ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
		//[storageManager resetTestData];
		//[storageManager generateRandomRankingsDeletingExistent:YES];
	}
	
	[self.mainViewController reloadApplications];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender 
{
    NSError *error = nil;
	if (![[ARStorageManager sharedARStorageManager] commitChanges:&error]) {
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
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
    }
    return NSTerminateNow;
}

@end
