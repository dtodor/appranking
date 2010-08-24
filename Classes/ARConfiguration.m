//
//  Configuration.m
//  AppRanking
//
//  Created by Todor Dimitrov on 22.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import "ARConfiguration.h"
#import "JSON.h"
#import "SynthesizeSingleton.h"
#import "SBJSON+Additions.h"
#import "ARCategoryTuple.h"
#import "ARApplication.h"


NSString * const kConfigurationErrorDomain = @"ConfigurationErrorDomain";


@implementation ARConfiguration

SYNTHESIZE_SINGLETON_FOR_CLASS(ARConfiguration)

@synthesize appStoreIds, genres, applications;

- (NSDictionary *)loadDictionary:(NSString *)fileName error:(NSError **)error {
	NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"json"];
	NSString *data = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:error];
	if (data) {
		SBJsonParser *parser = [[SBJsonParser alloc] init];
		NSDictionary *retValue = [parser dictionaryWithString:data error:error];
		[parser release];
		return retValue;
	} else {
		return nil;
	}
}

- (NSArray *)loadArray:(NSString *)fileName error:(NSError **)error {
	NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"json"];
	NSString *data = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:error];
	if (data) {
		SBJsonParser *parser = [[SBJsonParser alloc] init];
		NSArray *retValue = [parser arrayWithString:data error:error];
		[parser release];
		return retValue;
	} else {
		return nil;
	}
}

- (NSError *)errorForUnderlyingError:(NSError *)error {
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:@"Configuration file is corrupt!" forKey:NSLocalizedDescriptionKey];
	if (error) {
		[userInfo setObject:error forKey:NSUnderlyingErrorKey];
	}
	return [NSError errorWithDomain:kConfigurationErrorDomain 
							   code:CorruptConfigurationFile 
						   userInfo:userInfo];
}

- (BOOL)loadApplications:(NSError **)error {
	NSError *underlyingError = nil;
	NSArray *apps = [self loadArray:@"applications" error:&underlyingError];
	if (underlyingError) {
		if (error) {
			*error = [self errorForUnderlyingError:underlyingError];
		}
		return NO;
	}
	if (!apps) {
		return NO;
	}
	NSMutableDictionary *applicationsTmp = [NSMutableDictionary dictionary];
	for (NSUInteger i=0; i<[apps count]; i++) {
		NSDictionary *appDict = [apps dictionaryAtIndex:i error:&underlyingError];
		if (underlyingError) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			return NO;
		}
		ARApplication *app = [[ARApplication alloc] initWithDictionary:appDict error:&underlyingError];
		if (underlyingError) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			return NO;
		}
		for (ARCategoryTuple *tuple in app.categories) {
			NSMutableArray *apps = [applicationsTmp objectForKey:tuple];
			if (!apps) {
				apps = [NSMutableArray array];
				[applicationsTmp setObject:apps forKey:tuple];
			}
			[apps addObject:app];
		}
	}
	applications = [applicationsTmp retain];
	return YES;
}

- (BOOL)loadConfiguration:(NSError **)error {
	@synchronized(self) {
		if (appStoreIds) {
			return YES;
		}
		appStoreIds = [[self loadDictionary:@"app-store-ids" error:error] retain];
		if (!appStoreIds) {
			NSLog(@"Unable to load iTunes store ids, error = %@", (error)?[*error localizedDescription]:@"-");
			return NO;
		}
		genres = [[self loadDictionary:@"genres" error:error] retain];
		if (!genres) {
			NSLog(@"Unable to load iTunes categories, error = %@", (error)?[*error localizedDescription]:@"-");
			return NO;
		}
		if (![self loadApplications:error]) {
			NSLog(@"Unable to load applications, error = %@", (error)?[*error localizedDescription]:@"-");
			return NO;
		}
		return YES;
	}
}

@end
