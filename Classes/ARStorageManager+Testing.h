/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "ARStorageManager.h"
#import "ARApplication.h"
#import "ARCategoryTuple.h"


@interface ARStorageManager(Testing)

- (void)resetTestData;
- (void)generateRandomRankingsDeletingExistent:(BOOL)deleteExistent;
- (NSMutableArray *)testRanksForApplication:(ARApplication *)app inCategory:(ARCategoryTuple *)category;

@end
