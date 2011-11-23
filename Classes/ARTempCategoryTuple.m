//
//  ARTempCategoryTuple.m
//  AppRanking
//
//  Created by Todor Dimitrov on 31.08.10.
//  Copyright 2011 Todor Dimitrov. All rights reserved.
//

#import "ARTempCategoryTuple.h"
#import "ARStorageManager.h"


@implementation ARTempCategoryTuple

@synthesize name;
@synthesize type;

- (void)dealloc {
	[name release], name = nil;
	[type release], type = nil;
	[super dealloc];
}

- (BOOL)validateValue:(id *)ioValue forKey:(NSString *)inKey error:(NSError **)outError {
	if ([inKey isEqualToString:@"type"]) {
		if (*ioValue == nil) {
			if (outError) {
				*outError = [NSError errorWithDomain:@"ARTempCategoryTupleErrorDomain" 
												code:0 
											userInfo:[NSDictionary dictionaryWithObject:@"Category type cannot be null" 
																				 forKey:NSLocalizedDescriptionKey]];
			}
			return NO;
		}
	}
	return YES;
}

- (BOOL)isEqual:(id)object {
	if (object == self)
        return YES;
    if (!object || ![object isKindOfClass:[self class]])
        return NO;
	
	ARTempCategoryTuple *ref = (ARTempCategoryTuple *)object;
	if ((self.name && !ref.name) || (!self.name && ref.name)) {
		return NO;
	}
	BOOL result = YES;
	if (self.name) {
		result = [self.name isEqualToString:ref.name];
	} 
	if (result) {
		if ((self.type && !ref.type) || (!self.type && ref.type)) {
			result = NO;
		} else {
			result = !self.type || [self.type isEqual:ref.type];
		}
	}
	return result;
}

- (NSUInteger)hash {
	int prime = 31;
	int result = prime;
	result += prime * [self.name hash];
	result += prime * [self.type hash];
	return result;
}

- (BOOL)validate:(NSError **)error {
	return [self validateValue:&type forKey:@"type" error:error];
}

- (BOOL)fetchCorrespondingCategory:(ARCategoryTuple **)category error:(NSError **)error {
	NSManagedObjectContext *managedObjectContext = [ARStorageManager sharedARStorageManager].managedObjectContext;
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"ARCategoryTuple" inManagedObjectContext:managedObjectContext]];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@ and type == %d", self.name, [self.type intValue]];
	[fetchRequest setPredicate:predicate];
	[fetchRequest setFetchLimit:1];
	
	NSArray *categories = [managedObjectContext executeFetchRequest:fetchRequest error:error];
	if (!categories) {
		return NO;
	} else {
		if ([categories count] == 1) {
			*category = [categories lastObject];
		}
	}
	return YES;
}

@end
