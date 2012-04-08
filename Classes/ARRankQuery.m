/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
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
@property (nonatomic, strong) ARCategoryTuple *category;
@property (nonatomic, strong) NSDictionary *ranks;
@property (nonatomic, strong) NSDictionary *icons;
@property (nonatomic, getter=isCached) BOOL cached;
@property (nonatomic, strong) NSDate *expiryDate;

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSData *receivedData;
@property (nonatomic) BOOL started;
@property (nonatomic) BOOL canceled;
@property (nonatomic, strong) NSURL *url;

+ (dispatch_queue_t)cacheAccessSerialQueue;

@end


@implementation ARRankQuery

@synthesize country = _country;
@synthesize category = _category;
@synthesize delegate = _delegate;
@synthesize ranks = _ranks;
@synthesize icons = _icons;
@synthesize cached = _cached;
@synthesize expiryDate = _expiryDate;

@synthesize connection = _connection;
@synthesize receivedData = _receivedData;
@synthesize started = _started;
@synthesize canceled = _canceled;
@synthesize url = _url;

+ (dispatch_queue_t)cacheAccessSerialQueue 
{
	static dispatch_queue_t queue;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		queue = dispatch_queue_create("de.todordimitrov.appranking.cache-access-serial-queue", NULL);
	});
	return queue;
}

#pragma mark -
#pragma mark Query logic

- (NSError *)errorForUnderlyingError:(NSError *)error 
{
	return [NSError errorWithDomain:kErrorDomain 
							   code:UnableToParseFeed 
						   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unable to parse iTunes feed!", NSLocalizedDescriptionKey, 
									 error, NSUnderlyingErrorKey, nil]];
}

- (BOOL)parseFeed:(NSDictionary *)feed error:(NSError **)error 
{
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
		
		NSArray *apps = [_ranks allKeys];
		for (NSString *appName in apps) {
			if ([label isEqualToString:appName]) {
				NSNumber *rank = [NSNumber numberWithInt:i+1];
				found++;
				[(NSMutableDictionary *)_ranks setObject:rank forKey:appName];
				
				NSArray *images = [entry arrayForKey:@"im:image" error:NULL];
				if (images && [images count] > 0) {
					NSDictionary *image = [images dictionaryAtIndex:([images count]-1) error:NULL];
					if (image) {
						NSString *imageUrl = [image stringForKey:@"label" error:NULL];
						if (imageUrl) {
							[(NSMutableDictionary *)_icons setObject:imageUrl forKey:appName];
						}
					}
				}
			}
		}
		if (found == [_ranks count]) {
			break;
		}
	}
	return YES;
}

- (void)retrieveRank 
{
	void (^failBlock)(NSError *error) = ^(NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (self.cached) {
				[[ARRSSFeedCache sharedARRSSFeedCache] removeCachedFeedForCategory:self.category country:self.country];
			}
			if (self.delegate) {
				[self.delegate query:self didFailWithError:error];
			}
		});
	};
	
	void (^successBlock)() = ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			if (self.delegate) {
				[self.delegate queryDidFinish:self];
			}
		});
	};
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString *jsonString = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
		SBJsonParser *parser = [[SBJsonParser alloc] init];
		NSError *error = nil;
		NSDictionary *feed = [parser dictionaryWithString:jsonString error:&error];
		
		if (!feed) {
			failBlock(error);
		} else {
			if ([self parseFeed:feed error:&error]) {
				successBlock();
			} else {
				failBlock(error);
			}
		}
	});
}

#pragma mark -
#pragma mark Lifecycle

- (id)initWithCountry:(NSString *)aCountry category:(ARCategoryTuple *)aCategory 
{
	self = [super init];
	if (self != nil) {
		assert(aCategory);
		assert(aCountry);
		self.url = [aCategory rankingURLForCountry:aCountry];
		if (!self.url) {
			self = nil;
		} else {
			self.ranks = [NSMutableDictionary dictionaryWithCapacity:[aCategory.applications count]];
			self.icons = [NSMutableDictionary dictionaryWithCapacity:[aCategory.applications count]];
			for (ARApplication *app in aCategory.applications) {
				[(NSMutableDictionary *)_ranks setObject:[NSNull null] forKey:app.name];
			}
			self.country = aCountry;
			self.category = aCategory;
		}
	}
	return self;
}

- (void)start 
{
	assert(!self.started);
	self.started = YES;
	
	dispatch_async([ARRankQuery cacheAccessSerialQueue], ^{
		NSDate *expDate = nil;
		NSData *cachedData = [[ARRSSFeedCache sharedARRSSFeedCache] retrieveCachedFeedForCategory:self.category country:self.country expiryDate:&expDate];
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!cachedData) {
				NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url 
																	   cachePolicy:NSURLRequestUseProtocolCachePolicy 
																   timeoutInterval:60.0];
				
				[request setValue:@"text/javascript" forHTTPHeaderField:@"Content-Type"];
				[request setValue:@"text/javascript" forHTTPHeaderField:@"Accept"];
				[request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
				
				self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
				if (self.connection) {
					self.receivedData = [[NSMutableData alloc] init];
					[self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
					[self.connection start];
				} else {
					if (self.delegate && !self.canceled) {
						NSError *error = [NSError errorWithDomain:@"ARRankQueryErrorDomain" 
															 code:0 
														 userInfo:[NSDictionary dictionaryWithObject:@"Unable to open connection to RSS feed" 
																							  forKey:NSLocalizedDescriptionKey]];
						[self.delegate query:self didFailWithError:error];
					}
				}
			} else {
				assert(expDate);
				self.expiryDate = expDate;
				self.cached = YES;
				self.receivedData = cachedData;
				[self retrieveRank];
			}
		});
	});
}

- (void)cancel 
{
	if (self.connection) {
		[self.connection cancel];
	}
	self.canceled = YES;
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
	self.receivedData = nil;
	if (self.delegate && !self.canceled) {
		[self.delegate query:self didFailWithError:error];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
	[(NSMutableData *)self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
	dispatch_async([ARRankQuery cacheAccessSerialQueue], ^{
		[[ARRSSFeedCache sharedARRSSFeedCache] cacheFeed:self.receivedData forCategory:self.category country:self.country];
	});
	if (!self.canceled) {
		[self retrieveRank];
	}
}

@end
