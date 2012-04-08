/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "ARApplication.h"
#import "ARCategoryTuple.h"
#import "ARRankQuery.h"


@interface ARStorageManager : NSObject

@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong, readonly) NSDate *timestamp;

- (void)updateTimestamp;

+ (ARStorageManager *)sharedARStorageManager;

- (BOOL)commitChanges:(NSError **)error;
- (void)tryDeletingUnusedCategories;
- (NSArray *)rankedCountriesForApplication:(ARApplication *)app inCategory:(ARCategoryTuple *)category error:(NSError **)error;
- (NSArray *)rankEntriesForApplication:(ARApplication *)app 
							inCategory:(ARCategoryTuple *)category 
							 countries:(NSArray *)countries
								  from:(NSDate *)from
								 until:(NSDate *)until
								 error:(NSError **)error;

- (BOOL)insertRankEntry:(NSNumber *)rank forApplication:(ARApplication *)app query:(ARRankQuery *)query error:(NSError **)error;

@end
