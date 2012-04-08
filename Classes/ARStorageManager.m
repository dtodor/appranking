/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARStorageManager.h"
#import "ARRankEntry.h"
#import "ARRSSFeedCache.h"

@interface ARStorageManager()

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSDate *timestamp;

@end


@implementation ARStorageManager

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize timestamp = _timestamp;

+ (ARStorageManager *)sharedARStorageManager
{
    static dispatch_once_t onceToken;
    static ARStorageManager *singleton;
    dispatch_once(&onceToken, ^{
        singleton = [[ARStorageManager alloc] init];
    });
    return  singleton;
}

- (void)updateTimestamp 
{
	self.timestamp = [NSDate date];
}

- (id)init 
{
	self = [super init];
	if (self != nil) {
		[self updateTimestamp];
	}
	return self;
}

- (NSString *)applicationSupportDirectory 
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"AppRanking"];
}

- (NSManagedObjectModel *)managedObjectModel 
{
    if (_managedObjectModel) return _managedObjectModel;
    self.managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator 
{
    if (_persistentStoreCoordinator) return _persistentStoreCoordinator;
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
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
												  configuration:nil 
															URL:url 
														options:options 
														  error:&error]){
        [[NSApplication sharedApplication] presentError:error];
		self.persistentStoreCoordinator = nil;
        return nil;
    }    
	
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext 
{
    if (_managedObjectContext) return _managedObjectContext;
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    [self.managedObjectContext setPersistentStoreCoordinator:coordinator];
	
    return _managedObjectContext;
}

#pragma mark -
#pragma mark Public interface

- (BOOL)commitChanges:(NSError **)error 
{
	if (!self.managedObjectContext) return YES;
	
    if (![self.managedObjectContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NO;
    }
	
    if (![self.managedObjectContext hasChanges]) return YES;
	
    return [self.managedObjectContext save:error];
}

- (void)tryDeletingUnusedCategories 
{
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
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

- (NSArray *)rankedCountriesForApplication:(ARApplication *)app inCategory:(ARCategoryTuple *)category error:(NSError **)error 
{
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
	return objects;
}

- (BOOL)insertRankEntry:(NSNumber *)rank forApplication:(ARApplication *)app query:(ARRankQuery *)query error:(NSError **)error 
{
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
