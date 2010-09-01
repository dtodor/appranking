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

#import "ARAppDetailsWindowController.h"
#import "ARStorageManager.h"
#import "ARConfiguration.h"
#import "ARTempCategoryTuple.h"


@implementation ARAppDetailsWindowController

@synthesize application;
@synthesize tempCategories;

- (id)initWithWindowNibName:(NSString *)windowNibName {
	if (self = [super initWithWindowNibName:windowNibName]) {
		[self addObserver:self forKeyPath:@"application" options:NSKeyValueObservingOptionNew context:NULL];
	}
	return self;
}

- (void)windowDidLoad {
	[super windowDidLoad];
	if (!self.application) {
		self.application = nil;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (!self.application) {
		ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
		self.application = [NSEntityDescription insertNewObjectForEntityForName:@"ARApplication" 
														 inManagedObjectContext:storageManager.managedObjectContext];
		self.tempCategories = [NSMutableArray array];
	} else {
		NSMutableArray *categories = [NSMutableArray array];
		for (ARCategoryTuple *category in self.application.categories) {
			ARTempCategoryTuple *tempCategory = [[ARTempCategoryTuple alloc] init];
			tempCategory.name = category.name;
			tempCategory.type = category.type;
			[categories addObject:tempCategory];
			[tempCategory release];
		}
		self.tempCategories = categories;
	}
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"application"];
	self.tempCategories = nil;
	self.application = nil;
	[super dealloc];
}

- (NSArray *)categoryNames {
	static dispatch_once_t once;
	static NSArray *names;
	dispatch_once(&once, ^{
		NSArray *categories = [[ARConfiguration sharedARConfiguration].genres allKeys];
		names = [[categories sortedArrayUsingSelector:@selector(compare:)] retain];
	});
	return names;
}

- (NSArray *)categoryTypeNames {
	return [ARCategoryTuple typeNames];
}

- (BOOL)validateTempCategories:(NSError **)error {
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

- (BOOL)replaceCategories:(NSError **)error {
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

- (IBAction)commitChanges:(NSButton *)sender {
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

- (IBAction)discardChanges:(NSButton *)sender {
	ARStorageManager *storageManager = [ARStorageManager sharedARStorageManager];
	[storageManager.managedObjectContext rollback];
	NSWindow *sheet = [self window];
	[NSApp endSheet:sheet returnCode:DidSaveChanges];
	[sheet orderOut:nil];
}

@end
