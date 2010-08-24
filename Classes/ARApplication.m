//
//  Application.m
//  AppRanking
//
//  Created by Todor Dimitrov on 24.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import "ARApplication.h"
#import "SBJSON+Additions.h"


@implementation ARApplication

@synthesize name, categories;

- (NSError *)errorForUnderlyingError:(NSError *)error {
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:@"Unable to create application from dictionary" forKey:NSLocalizedDescriptionKey];
	if (error) {
		[userInfo setObject:error forKey:NSUnderlyingErrorKey];
	}
	return [NSError errorWithDomain:@"ApplicationErrorDomain" code:0 userInfo:userInfo];
}

- (id)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
	self = [super init];
	if (self) {
		NSError *underlyingError = nil;

		NSString *appName = [dictionary stringForKey:@"name" error:&underlyingError];
		if (underlyingError) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			[self release];
			self = nil;
			return self;
		}
		if (!appName) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			[self release];
			self = nil;
			return self;
		}
		name = [appName copy];
		NSArray *tuples = [dictionary arrayForKey:@"tuples" error:&underlyingError];
		if (underlyingError) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			[self release];
			self = nil;
			return self;
		}
		if ([tuples count] == 0) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			[self release];
			self = nil;
			return self;
		}
		categories = [NSMutableSet set];
		for (int j=0; j<[tuples count]; j++) {
			NSDictionary *tuple = [tuples dictionaryAtIndex:j error:&underlyingError];
			if (underlyingError) {
				if (error) {
					*error = [self errorForUnderlyingError:underlyingError];
				}
				[self release];
				self = nil;
				return self;
			}
			ARCategoryTuple *categoryTuple = [[ARCategoryTuple alloc] initWithDictionary:tuple error:&underlyingError];
			if (underlyingError) {
				if (error) {
					*error = [self errorForUnderlyingError:underlyingError];
				}
				[self release];
				self = nil;
				return self;
			}
			[categories addObject:categoryTuple];
			[categoryTuple release];
		}
	}
	return self;
}

- (void)dealloc {
	[name release];
	[categories release];
	[super dealloc];
}

@end
