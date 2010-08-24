//
//  Download.m
//  AppRanking
//
//  Created by Todor Dimitrov on 22.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import "ARRankQuery.h"
#import "ARConfiguration.h"
#import "JSON.h"
#import "SBJSON+Additions.h"
#import "ARApplication.h"


NSString * const kErrorDomain = @"RankQueryErrorDomain";


@implementation ARRankQuery

@synthesize country, category, delegate, ranks;

- (id)initWithCountry:(NSString *)aCountry category:(ARCategoryTuple *)aCategory applications:(NSArray *)apps {
	self = [super init];
	if (self != nil) {
		assert([apps count] > 0);
		assert(aCountry);
		NSURL *url = [aCategory rankingURLForCountry:aCountry];
		if (!url) {
			[self release];
			self = nil;
		} else {
			ranks = [[NSMutableDictionary alloc] initWithCapacity:[apps count]];
			for (ARApplication *app in apps) {
				[ranks setObject:[NSNull null] forKey:app.name];
			}
			country = [aCountry copy];
			category = [aCategory retain];
			
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
			[request setValue:@"text/javascript" forHTTPHeaderField:@"Content-Type"];
			[request setValue:@"text/javascript" forHTTPHeaderField:@"Accept"];
			[request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
			
			connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
			if (connection) {
				receivedData = [[NSMutableData alloc] init];
			} else {
				[self release];
				self = nil;
			}
		}
	}
	return self;
}

- (void)dealloc {
	[ranks release];
	[receivedData release];
	[connection release];
	[country release];
	[category release];
	[super dealloc];
}

- (void)start {
	@synchronized(self) {
		assert(!started);
		started = YES;
	}
	[connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[connection start];
}

#pragma mark -
#pragma mark Query logic

- (NSError *)errorForUnderlyingError:(NSError *)error {
	return [NSError errorWithDomain:kErrorDomain 
							   code:UnableToParseFeed 
						   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to parse iTunes feed!", NSLocalizedDescriptionKey, 
									 error, NSUnderlyingErrorKey, nil]];
}

- (BOOL)parseFeed:(NSDictionary *)feed error:(NSError **)error {
	NSError *underlyingError = nil;
	NSDictionary *feedDict = [feed dictionaryForKey:@"feed" error:&underlyingError];
	if (underlyingError) {
		if (error) {
			*error = [self errorForUnderlyingError:underlyingError];
		}
		return NO;
	}
	NSArray *entries = [feedDict arrayForKey:@"entry" error:&underlyingError];
	if (underlyingError) {
		if (error) {
			*error = [self errorForUnderlyingError:underlyingError];
		}
		return NO;
	}
	NSUInteger found = 0;
	for (NSUInteger i=0; i<[entries count]; i++) {
		NSDictionary *entry = [entries dictionaryAtIndex:i error:&underlyingError];
		if (underlyingError) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			return NO;
		}

		NSDictionary *name = [entry dictionaryForKey:@"im:name" error:&underlyingError];
		if (underlyingError) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			return NO;
		}
		
		NSString *label = [name stringForKey:@"label" error:&underlyingError];
		if (underlyingError) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			return NO;
		}
		NSArray *apps = [ranks allKeys];
		for (NSString *appName in apps) {
			if ([label isEqualToString:appName]) {
				NSNumber *rank = [NSNumber numberWithInt:i+1];
				found++;
				[ranks setObject:rank forKey:appName];
			}
		}
		if (found == [ranks count]) {
			break;
		}
	}
	return YES;
}

- (void)retrieveRank {
	void (^failBlock)(NSError *error) = ^(NSError *error) {
		[error retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			if (delegate) {
				[delegate query:self didFailWithError:error];
			}
			[error release];
		});
	};
	
	void (^successBlock)() = ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			if (delegate) {
				[delegate queryDidFinish:self];
			}
		});
	};
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		NSString *jsonString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
		[receivedData release];
		receivedData = nil;
		SBJsonParser *parser = [[SBJsonParser alloc] init];
		NSError *error = nil;
		NSDictionary *feed = [parser dictionaryWithString:jsonString error:&error];
		[jsonString release];
		[parser release];
		
		if (!feed) {
			failBlock(error);
		} else {
			if ([self parseFeed:feed error:&error]) {
				successBlock();
			} else {
				failBlock(error);
			}
		}

		[pool drain];
	});
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[receivedData release];
	receivedData = nil;
	if (delegate) {
		[delegate query:self didFailWithError:error];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[self retrieveRank];
}

@end
