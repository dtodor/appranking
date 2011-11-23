/*
 * Copyright (c) 2011 Todor Dimitrov
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

#import "ARRSSFeedCache.h"
#import "SynthesizeSingleton.h"
#import "GTMNSData+zlib.h"
#import "ARStorageManager.h"


@interface ARRSSFeedCache()

@property (nonatomic, retain) NSFileManager *fileManager;

@end


@implementation ARRSSFeedCache

SYNTHESIZE_SINGLETON_FOR_CLASS(ARRSSFeedCache)

@synthesize fileManager;

- (id)init {
	self = [super init];
	if (self != nil) {
		self.fileManager = [[[NSFileManager alloc] init] autorelease];
	}
	return self;
}

- (NSString *)applicationCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    return [basePath stringByAppendingPathComponent:bundleId];
}

- (NSString *)cacheFileNameForCategory:(ARCategoryTuple *)category country:(NSString *)country {
	assert(category);
	assert(country);
	NSString *categoryDir = [[self applicationCacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ [%@]", 
																							  category.name, [category typeName]]];
	BOOL isDirectory;
	if (![fileManager fileExistsAtPath:categoryDir isDirectory:&isDirectory] || !isDirectory) {
		NSError *error = nil;
		if (![fileManager createDirectoryAtPath:categoryDir withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSLog(@"Unable to create cache directory '%@', error = %@", categoryDir, [error localizedDescription]);
			return nil;
		}
	}
	
	return [categoryDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json.gz", country]];
}

#define CACHE_EXPIRY_INTERVAL 3600

+ (NSTimeInterval)expiryInterval {
	return CACHE_EXPIRY_INTERVAL;
}

- (NSData *)retrieveCachedFeedForCategory:(ARCategoryTuple *)category country:(NSString *)country expiryDate:(NSDate **)expiryDate {
	NSString *cacheFile = [self cacheFileNameForCategory:category country:country];
	if (!cacheFile) {
		return nil;
	}
	if (![fileManager fileExistsAtPath:cacheFile]) {
		return nil;
	}
	NSError *error = nil;
	NSDictionary *attributes = [fileManager attributesOfItemAtPath:cacheFile error:&error];
	if (!attributes) {
		NSLog(@"Unable to retrieve attributes for cache file '%@', error = %@", cacheFile, [error localizedDescription]);
		return nil;
	}
	NSDate *lastModificationDate = [attributes objectForKey:NSFileModificationDate];
	if (!lastModificationDate || -[lastModificationDate timeIntervalSinceNow] > CACHE_EXPIRY_INTERVAL) {
		error = nil;
		if (![fileManager removeItemAtPath:cacheFile error:&error]) {
			NSLog(@"Unable to remove stale cache file '%@', error = %@", cacheFile, [error localizedDescription]);
		}
		return nil;
	}

	NSData *cachedData = [NSData dataWithContentsOfFile:cacheFile options:0 error:&error];
	if (!cachedData) {
		NSLog(@"Unable to read cache file '%@', error = %@", cacheFile, [error localizedDescription]);
		error = nil;
		if (![fileManager removeItemAtPath:cacheFile error:&error]) {
			NSLog(@"Unable to remove corrupt cache file '%@', error = %@", cacheFile, [error localizedDescription]);
		}
		return nil;
	}

	NSData *data = [NSData gtm_dataByInflatingData:cachedData];
	if (!data) {
		error = nil;
		NSLog(@"Unable to inflate cache file '%@'", cacheFile);
		if (![fileManager removeItemAtPath:cacheFile error:&error]) {
			NSLog(@"Unable to remove corrupt cache file '%@', error = %@", cacheFile, [error localizedDescription]);
		}
		return nil;
	}
	
	if (expiryDate) {
		*expiryDate = [NSDate dateWithTimeInterval:CACHE_EXPIRY_INTERVAL sinceDate:lastModificationDate];
	}
	
	return data;
}

- (void)cacheFeed:(NSData *)feedData forCategory:(ARCategoryTuple *)category country:(NSString *)country {
	assert(feedData);
	NSString *cacheFile = [self cacheFileNameForCategory:category country:country];
	if (!cacheFile) {
		return;
	}
	NSError *error = nil;
	if ([fileManager fileExistsAtPath:cacheFile] && ![fileManager removeItemAtPath:cacheFile error:&error]) {
		NSLog(@"Unable to remove cache file '%@', error = %@", cacheFile, [error localizedDescription]);
		return;
	}
	NSData *gzippedFeedData = [NSData gtm_dataByGzippingData:feedData compressionLevel:9];
	if (!gzippedFeedData) {
		NSLog(@"Unable to deflate feed data for cache file '%@'", cacheFile);
	} else {
		if (![gzippedFeedData writeToFile:cacheFile options:NSDataWritingAtomic error:&error]) {
			NSLog(@"Unable to persist cache file '%@', error = %@", cacheFile, [error localizedDescription]);
		} else {
			NSDictionary *attr = [NSDictionary dictionaryWithObject:[ARStorageManager sharedARStorageManager].timestamp forKey:NSFileModificationDate];
			if (![fileManager setAttributes:attr ofItemAtPath:cacheFile error:&error]) {
				NSLog(@"Unable to change modification date for cache file '%@', error = %@", cacheFile, [error localizedDescription]);
			}
		}
	}
}

- (void)removeCachedFeedForCategory:(ARCategoryTuple *)category country:(NSString *)country {
	NSString *cacheFile = [self cacheFileNameForCategory:category country:country];
	if (!cacheFile || ![fileManager fileExistsAtPath:cacheFile]) {
		return;
	}
	NSError *error = nil;
	if (![fileManager removeItemAtPath:cacheFile error:&error]) {
		NSLog(@"Unable to remove cache file '%@', error = %@", cacheFile, [error localizedDescription]);
	}
}

@end
