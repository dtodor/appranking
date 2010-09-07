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

#import "ARRankQuery.h"
#import "ARConfiguration.h"
#import "JSON.h"
#import "SBJSON+Additions.h"
#import "ARApplication.h"
#import "ARRSSFeedCache.h"


NSString * const kErrorDomain = @"RankQueryErrorDomain";


@interface ARRankQuery()

@property (nonatomic, copy) NSString *country;
@property (nonatomic, retain) ARCategoryTuple *category;
@property (nonatomic, retain) NSMutableDictionary *ranks;
@property (nonatomic, retain) NSMutableDictionary *icons;
@property (nonatomic, getter=isCached) BOOL cached;
@property (nonatomic, retain) NSDate *expiryDate;

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSData *receivedData;
@property (nonatomic) BOOL started;
@property (nonatomic) BOOL canceled;

@end



@implementation ARRankQuery

@synthesize country;
@synthesize category;
@synthesize delegate;
@synthesize ranks;
@synthesize icons;
@synthesize cached;
@synthesize expiryDate;

@synthesize connection;
@synthesize receivedData;
@synthesize started;
@synthesize canceled;

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
				
				NSArray *images = [entry arrayForKey:@"im:image" error:NULL];
				if (images && [images count] > 0) {
					NSDictionary *image = [images dictionaryAtIndex:([images count]-1) error:NULL];
					if (image) {
						NSString *imageUrl = [image stringForKey:@"label" error:NULL];
						if (imageUrl) {
							[icons setObject:imageUrl forKey:appName];
						}
					}
				}
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
			if (cached) {
				[[ARRSSFeedCache sharedARRSSFeedCache] removeCachedFeedForCategory:category country:country];
			}
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
#pragma mark Lifecycle

- (id)initWithCountry:(NSString *)aCountry category:(ARCategoryTuple *)aCategory {
	self = [super init];
	if (self != nil) {
		assert(aCategory);
		assert(aCountry);
		NSURL *url = [aCategory rankingURLForCountry:aCountry];
		if (!url) {
			[self release];
			self = nil;
		} else {
			self.ranks = [NSMutableDictionary dictionaryWithCapacity:[aCategory.applications count]];
			self.icons = [NSMutableDictionary dictionaryWithCapacity:[aCategory.applications count]];
			for (ARApplication *app in aCategory.applications) {
				[ranks setObject:[NSNull null] forKey:app.name];
			}
			self.country = aCountry;
			self.category = aCategory;

			NSDate *expDate = nil;
			NSData *cachedData = [[ARRSSFeedCache sharedARRSSFeedCache] retrieveCachedFeedForCategory:category country:country expiryDate:&expDate];
			
			if (!cachedData) {
				NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
				[request setValue:@"text/javascript" forHTTPHeaderField:@"Content-Type"];
				[request setValue:@"text/javascript" forHTTPHeaderField:@"Accept"];
				[request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
				
				self.connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO] autorelease];
				if (self.connection) {
					self.receivedData = [[NSMutableData alloc] init];
				} else {
					[self release];
					self = nil;
				}
			} else {
				assert(expDate);
				self.expiryDate = expDate;
				self.cached = YES;
				self.receivedData = cachedData;
			}
		}
	}
	return self;
}

- (void)dealloc {
	self.expiryDate = nil;
	self.icons = nil;
	self.ranks = nil;
	self.receivedData = nil;
	self.connection = nil;
	self.country = nil;
	self.category = nil;
	[super dealloc];
}

- (void)start {
	assert(!started);
	self.started = YES;
	if (connection) {
		[connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[connection start];
	} else {
		[self retrieveRank];
	}
}

- (void)cancel {
	if (connection) {
		[connection cancel];
	}
	self.canceled = YES;
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	self.receivedData = nil;
	if (delegate && !canceled) {
		[delegate query:self didFailWithError:error];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[(NSMutableData *)receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[[ARRSSFeedCache sharedARRSSFeedCache] cacheFeed:receivedData forCategory:category country:country];
	if (!canceled) {
		[self retrieveRank];
	}
}

@end
