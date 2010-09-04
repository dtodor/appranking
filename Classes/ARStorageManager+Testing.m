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

#import "ARStorageManager+Testing.h"
#import "ARCategoryTuple.h"
#import "ARApplication.h"
#import "ARRankEntry.h"
#import "ARConfiguration.h"


@implementation ARStorageManager(Testing)

- (void)deleteAllEntities:(NSString *)entityName {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    [fetchRequest release];
	if (items) {
		for (NSManagedObject *managedObject in items) {
			[self.managedObjectContext deleteObject:managedObject];
		}
	}
}

- (void)resetTestData {
	[self deleteAllEntities:@"ARApplication"];
	[self deleteAllEntities:@"ARCategoryTuple"];
	
	{
		ARCategoryTuple *tuple = [NSEntityDescription insertNewObjectForEntityForName:@"ARCategoryTuple" inManagedObjectContext:self.managedObjectContext];
		tuple.name = @"Education";
		tuple.tupleType = Top_Free_Apps;
		
		ARApplication *app = [NSEntityDescription insertNewObjectForEntityForName:@"ARApplication" inManagedObjectContext:self.managedObjectContext];
		app.appStoreId = [NSNumber numberWithInt:378677412];
		app.name = @"Spel It Rite 2";
		app.categories = [NSSet setWithObject:tuple];
	}
	
	{
		ARCategoryTuple *tuple = [NSEntityDescription insertNewObjectForEntityForName:@"ARCategoryTuple" inManagedObjectContext:self.managedObjectContext];
		tuple.name = @"Education";
		tuple.tupleType = Top_Paid_Apps;
		
		ARApplication *app = [NSEntityDescription insertNewObjectForEntityForName:@"ARApplication" inManagedObjectContext:self.managedObjectContext];
		app.appStoreId = [NSNumber numberWithInt:335608149];
		app.name = @"Call For Papers";
		app.categories = [NSSet setWithObject:tuple];
	}
	
	NSError *error = nil;
	if (![self.managedObjectContext save:&error]) {
		NSLog(@"Unable to persist new test data, error = %@", [error localizedDescription]);
	}
}

- (NSArray *)applications {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ARApplication" 
											  inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
	NSError *error = nil;
	NSArray *apps = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];
	if (!apps) {
		NSLog(@"Unable to retrieve applications list, error = %@", [error localizedDescription]);
	}
	return apps;
}

- (void)generateRandomRankingsDeletingExistent:(BOOL)deleteExistent {
	static NSUInteger numberOfEntriesPerCategory = 500;
	static NSUInteger numberOfCountries = 4;
	
	if (deleteExistent) {
		[self deleteAllEntities:@"ARRankEntry"];
		NSError *error = nil;
		if (![self.managedObjectContext save:&error]) {
			NSLog(@"Unable to delete existing rank entries, error = %@", [error localizedDescription]);
		}
	}
	
	NSArray *allCountries = [[ARConfiguration sharedARConfiguration].appStoreIds allKeys];
	NSDate *startDate = [NSDate date];
	NSArray *apps = [self applications];
	if (!apps) {
		return;
	}
	
	for (ARApplication *app in apps) {
		for (ARCategoryTuple *category in app.categories) {
			NSMutableArray *countries = [NSMutableArray array];
			while ([countries count] < numberOfCountries || [countries count] == [allCountries count]) {
				NSString *country = [allCountries objectAtIndex:arc4random()%[allCountries count]];
				if (![countries containsObject:country]) {
					[countries addObject:country];
				}
			}

			for (NSUInteger i=0; i<numberOfEntriesPerCategory; i++) {
				ARRankEntry *entry = (ARRankEntry *)[NSEntityDescription insertNewObjectForEntityForName:@"ARRankEntry" 
																				  inManagedObjectContext:self.managedObjectContext];
				entry.application = app;
				entry.category = category;
				entry.country = [countries objectAtIndex:arc4random()%numberOfCountries];
				entry.rank = [NSNumber numberWithInt:(arc4random()%300)+1];
				entry.timestamp = [NSDate dateWithTimeInterval:i*3600 sinceDate:startDate];
			}
		}
	}
	
	NSError *error = nil;
	if (![self.managedObjectContext save:&error]) {
		NSLog(@"Unable to persist new random rank entries, error = %@", [error localizedDescription]);
	}
}

@end
