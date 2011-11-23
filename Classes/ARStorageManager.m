/*
 * Copyright (c) 2011 Todor Dimitrov
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

#import "ARStorageManager.h"
#import "SynthesizeSingleton.h"
#import "ARRankEntry.h"
#import "ARRSSFeedCache.h"

@interface ARStorageManager()

@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSDate *timestamp;

@end


@implementation ARStorageManager

SYNTHESIZE_SINGLETON_FOR_CLASS(ARStorageManager)

@synthesize persistentStoreCoordinator;
@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize timestamp;

- (void)updateTimestamp {
	self.timestamp = [NSDate date];
}

- (id)init {
	self = [super init];
	if (self != nil) {
		[self updateTimestamp];
	}
	return self;
}

- (NSString *)applicationSupportDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"AppRanking"];
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel) return managedObjectModel;
    self.managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if (![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL]) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath:[applicationSupportDirectory stringByAppendingPathComponent: @"storedata"]];
    self.persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom] autorelease];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
												  configuration:nil 
															URL:url 
														options:options 
														  error:&error]){
        [[NSApplication sharedApplication] presentError:error];
		self.persistentStoreCoordinator = nil;
        return nil;
    }    
	
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext) return managedObjectContext;
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    self.managedObjectContext = [[[NSManagedObjectContext alloc] init] autorelease];
    [managedObjectContext setPersistentStoreCoordinator:coordinator];
	
    return managedObjectContext;
}

#pragma mark -
#pragma mark Public interface

- (BOOL)commitChanges:(NSError **)error {
	if (!managedObjectContext) return YES;
	
    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NO;
    }
	
    if (![managedObjectContext hasChanges]) return YES;
	
    return [managedObjectContext save:error];
}

- (void)tryDeletingUnusedCategories {
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"ARCategoryTuple" inManagedObjectContext:self.managedObjectContext]];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"applications.@count == 0"]];
	NSError *error = nil;
	NSArray *categories = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	if (categories) {
		for (ARCategoryTuple *category in categories) {
			[self.managedObjectContext deleteObject:category];
		}
		if (![self.managedObjectContext save:&error]) {
			NSLog(@"Unable to delete unsued categories, error = %@", [error localizedDescription]);
		}
	} else {
		NSLog(@"Unable to retrieve unused categories, error = %@", [error localizedDescription]);
	}
}

- (NSArray *)rankedCountriesForApplication:(ARApplication *)app inCategory:(ARCategoryTuple *)category error:(NSError **)error {
	assert(app);
	assert(category);
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ARRankEntry" inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	NSDictionary *entityDict = [entity attributesByName];
	NSAttributeDescription *countryAttribute = [entityDict objectForKey:@"country"];
	[request setPropertiesToFetch:[NSArray arrayWithObject:countryAttribute]];
	[request setReturnsDistinctResults:YES];
	[request setResultType:NSDictionaryResultType];
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"country" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"application == %@ and category == %@", app, category]];
	NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:error];
	[request release];
	if (objects) {
		return [objects valueForKeyPath:@"country"];
	} else {
		return nil;
	}
}

- (NSArray *)rankEntriesForApplication:(ARApplication *)app 
							inCategory:(ARCategoryTuple *)category 
							 countries:(NSArray *)countries 
								  from:(NSDate *)from
								 until:(NSDate *)until
								 error:(NSError **)error {
	
	assert(app);
	assert(category);
	assert([countries count] > 0);
	assert(from);
	assert(until);
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ARRankEntry" inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	[request setPredicate:[NSPredicate predicateWithFormat:@"application == %@ and category == %@ and country in %@ and timestamp >= %@ and timestamp <= %@", 
						   app, category, countries, from, until]];
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:error];
	[request release];
	return objects;
}

- (BOOL)insertRankEntry:(NSNumber *)rank forApplication:(ARApplication *)app query:(ARRankQuery *)query error:(NSError **)error {
	if (query.cached) {
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"ARRankEntry" 
												  inManagedObjectContext:self.managedObjectContext];
		[fetchRequest setEntity:entity];
		[fetchRequest setFetchLimit:1];
		
		NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
		[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"application == %@ and category == %@ and country == %@ and rank == %@", 
									app, query.category, query.country, rank]];
		
		NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:error];
		[fetchRequest release];
		if (!result) {
			return NO;
		}
		if ([result count] == 1) {
			ARRankEntry *entry = [result objectAtIndex:0];
			NSTimeInterval difference = [query.expiryDate timeIntervalSinceDate:entry.timestamp];
			if (difference < [ARRSSFeedCache expiryInterval]) {
				NSLog(@"Entry for cached query exists");
				return YES;
			}
		}
	}
	ARRankEntry *entry = [NSEntityDescription insertNewObjectForEntityForName:@"ARRankEntry" inManagedObjectContext:self.managedObjectContext];
	entry.application = app;
	entry.category = query.category;
	entry.country = query.country;
	entry.rank = rank;
	entry.timestamp = self.timestamp;
	
	if (![self.managedObjectContext save:error]) {
		return NO;
	}
	return YES;
}

@end
