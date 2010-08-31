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


NSString * const kErrorDomain = @"RankQueryErrorDomain";


@implementation ARRankQuery

@synthesize country, category, delegate, ranks, icons;

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
			ranks = [[NSMutableDictionary alloc] initWithCapacity:[aCategory.applications count]];
			icons = [[NSMutableDictionary alloc] initWithCapacity:[aCategory.applications count]];
			for (ARApplication *app in aCategory.applications) {
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
	[icons release];
	[ranks release];
	[receivedData release];
	[connection release];
	[country release];
	[category release];
	[super dealloc];
}

- (void)start {
	assert(!started);
	started = YES;
	[connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[connection start];
}

- (void)cancel {
	[connection cancel];
	canceled = YES;
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
				
				NSArray *images = [entry arrayForKey:@"im:image" error:NULL];
				if (images && [images count] > 0) {
					NSDictionary *image = [images dictionaryAtIndex:0 error:NULL];
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
	if (delegate && !canceled) {
		[delegate query:self didFailWithError:error];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if (!canceled) {
		[self retrieveRank];
	}
}

@end
