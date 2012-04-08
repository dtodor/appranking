/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARAppDetailsWindowController.h"
#import "ARStorageManager.h"
#import "ARConfiguration.h"
#import "ARTempCategoryTuple.h"

@interface ARAppDetailsWindowController ()

@property (nonatomic, strong) NSMutableArray *tempCategories;
@property (nonatomic, readonly) NSArray *categoryNames;
@property (nonatomic, readonly) NSArray *categoryTypeNames;

- (IBAction)commitChanges:(NSButton *)sender;
- (IBAction)discardChanges:(NSButton *)sender;

@end

@implementation ARAppDetailsWindowController

@synthesize application = _application;
@synthesize tempCategories = _tempCategories;

- (id)initWithWindowNibName:(NSString *)windowNibName 
{
	if (self = [super initWithWindowNibName:windowNibName]) {
		[self addObserver:self forKeyPath:@"application" options:0 context:NULL];
	}
	return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"application"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
	if (!self.application) {
		ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
		self.application = [NSEntityDescription insertNewObjectForEntityForName:@"ARApplication" 
														 inManagedObjectContext:storageManager.managedObjectContext];
	} else {
		NSMutableArray *categories = [NSMutableArray array];
		for (ARCategoryTuple *category in self.application.categories) {
			ARTempCategoryTuple *tempCategory = [[ARTempCategoryTuple alloc] init];
			tempCategory.name = category.name;
			tempCategory.type = category.type;
			[categories addObject:tempCategory];
		}
		self.tempCategories = categories;
	}
}

- (NSArray *)categoryNames 
{
	static dispatch_once_t once;
	static NSArray *names;
	dispatch_once(&once, ^{
		NSArray *categories = [[ARConfiguration sharedARConfiguration].genres allKeys];
		names = [categories sortedArrayUsingSelector:@selector(compare:)];
	});
	return names;
}

- (NSArray *)categoryTypeNames 
{
	return [ARCategoryTuple typeNames];
}

- (BOOL)validateTempCategories:(NSError **)error 
{
	NSMutableSet *categories = [NSMutableSet set];
	for (ARTempCategoryTuple *category in self.tempCategories) {
		if (![category validate:error]) {
			return NO;
		}
		if ([categories containsObject:category]) {
			if (error) {
				*error = [NSError errorWithDomain:@"ARAppDetailsWindowControllerErrorDomain" 
											 code:0 
										 userInfo:[NSDictionary dictionaryWithObject:@"Duplicate categories" 
																			  forKey:NSLocalizedDescriptionKey]];
			}
			return NO;
		}
		[categories addObject:category];
	}
	return YES;
}

- (BOOL)replaceCategories:(NSError **)error 
{
	NSManagedObjectContext *managedObjectContext = [ARStorageManager sharedARStorageManager].managedObjectContext;
	NSMutableSet *newCategories = [NSMutableSet set];
	for (ARTempCategoryTuple *tempCategory in self.tempCategories) {
		ARCategoryTuple *category = nil;
		if (![tempCategory fetchCorrespondingCategory:&category error:error]) {
			return NO;
		}
		if (!category) {
			category = [NSEntityDescription insertNewObjectForEntityForName:@"ARCategoryTuple" inManagedObjectContext:managedObjectContext];
			category.name = tempCategory.name;
			category.type = tempCategory.type;
		}
		[newCategories addObject:category];
	}
	
	self.application.categories = newCategories;
	
	return YES;
}

- (IBAction)commitChanges:(NSButton *)sender 
{
	NSError *error = nil;
	if (![self validateTempCategories:&error]) {
		[self presentError:error];
		return;
	}
	if (![self replaceCategories:&error]) {
		[self presentError:error];
		return;
	}
	
	ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
	if (![storageManager.managedObjectContext save:&error]) {
		NSLog(@"Unable to save app info, error = %@", [error localizedDescription]);
		[self presentError:error];
		return;
	}
	
	NSWindow *sheet = [self window];
	[NSApp endSheet:sheet returnCode:DidSaveChanges];
	[sheet orderOut:nil];
}

- (IBAction)discardChanges:(NSButton *)sender 
{
	ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
	[storageManager.managedObjectContext rollback];
	NSWindow *sheet = [self window];
	[NSApp endSheet:sheet returnCode:DidDiscardChanges];
	[sheet orderOut:nil];
}

@end
