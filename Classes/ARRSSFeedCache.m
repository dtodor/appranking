/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARRSSFeedCache.h"
#import "GTMNSData+zlib.h"
#import "ARStorageManager.h"


@interface ARRSSFeedCache()

@property (nonatomic, strong) NSFileManager *fileManager;

@end


@implementation ARRSSFeedCache

@synthesize fileManager = _fileManager;

+ (ARRSSFeedCache *)sharedARRSSFeedCache
{
    static dispatch_once_t onceToken;
    static ARRSSFeedCache *singleton;
    dispatch_once(&onceToken, ^{
        singleton = [[ARRSSFeedCache alloc] init];
    });
    return singleton;
}

- (id)init 
{
	self = [super init];
	if (self != nil) {
		self.fileManager = [[NSFileManager alloc] init];
	}
	return self;
}

- (NSString *)applicationCacheDirectory 
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    return [basePath stringByAppendingPathComponent:bundleId];
}

- (NSString *)cacheFileNameForCategory:(ARCategoryTuple *)category country:(NSString *)country 
{
	assert(category);
	assert(country);
	NSString *categoryDir = [[self applicationCacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ [%@]", 
																							  category.name, [category typeName]]];
	BOOL isDirectory;
	if (![self.fileManager fileExistsAtPath:categoryDir isDirectory:&isDirectory] || !isDirectory) {
		NSError *error = nil;
		if (![self.fileManager createDirectoryAtPath:categoryDir withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSLog(@"Unable to create cache directory '%@', error = %@", categoryDir, [error localizedDescription]);
			return nil;
		}
	}
	
	return [categoryDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json.gz", country]];
}

#define CACHE_EXPIRY_INTERVAL 3600

+ (NSTimeInterval)expiryInterval 
{
	return CACHE_EXPIRY_INTERVAL;
}

- (NSData *)retrieveCachedFeedForCategory:(ARCategoryTuple *)category country:(NSString *)country expiryDate:(NSDate **)expiryDate 
{
	NSString *cacheFile = [self cacheFileNameForCategory:category country:country];
	if (!cacheFile) {
		return nil;
	}
	if (![self.fileManager fileExistsAtPath:cacheFile]) {
		return nil;
	}
	NSError *error = nil;
	NSDictionary *attributes = [self.fileManager attributesOfItemAtPath:cacheFile error:&error];
	if (!attributes) {
		NSLog(@"Unable to retrieve attributes for cache file '%@', error = %@", cacheFile, [error localizedDescription]);
		return nil;
	}
	NSDate *lastModificationDate = [attributes objectForKey:NSFileModificationDate];
	if (!lastModificationDate || -[lastModificationDate timeIntervalSinceNow] > CACHE_EXPIRY_INTERVAL) {
		error = nil;
		if (![self.fileManager removeItemAtPath:cacheFile error:&error]) {
			NSLog(@"Unable to remove stale cache file '%@', error = %@", cacheFile, [error localizedDescription]);
		}
		return nil;
	}

	NSData *cachedData = [NSData dataWithContentsOfFile:cacheFile options:0 error:&error];
	if (!cachedData) {
		NSLog(@"Unable to read cache file '%@', error = %@", cacheFile, [error localizedDescription]);
		error = nil;
		if (![self.fileManager removeItemAtPath:cacheFile error:&error]) {
			NSLog(@"Unable to remove corrupt cache file '%@', error = %@", cacheFile, [error localizedDescription]);
		}
		return nil;
	}

	NSData *data = [NSData gtm_dataByInflatingData:cachedData];
	if (!data) {
		error = nil;
		NSLog(@"Unable to inflate cache file '%@'", cacheFile);
		if (![self.fileManager removeItemAtPath:cacheFile error:&error]) {
			NSLog(@"Unable to remove corrupt cache file '%@', error = %@", cacheFile, [error localizedDescription]);
		}
		return nil;
	}
	
	if (expiryDate) {
		*expiryDate = [NSDate dateWithTimeInterval:CACHE_EXPIRY_INTERVAL sinceDate:lastModificationDate];
	}
	
	return data;
}

- (void)cacheFeed:(NSData *)feedData forCategory:(ARCategoryTuple *)category country:(NSString *)country 
{
	assert(feedData);
	NSString *cacheFile = [self cacheFileNameForCategory:category country:country];
	if (!cacheFile) {
		return;
	}
	NSError *error = nil;
	if ([self.fileManager fileExistsAtPath:cacheFile] && ![self.fileManager removeItemAtPath:cacheFile error:&error]) {
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
			if (![self.fileManager setAttributes:attr ofItemAtPath:cacheFile error:&error]) {
				NSLog(@"Unable to change modification date for cache file '%@', error = %@", cacheFile, [error localizedDescription]);
			}
		}
	}
}

- (void)removeCachedFeedForCategory:(ARCategoryTuple *)category country:(NSString *)country 
{
	NSString *cacheFile = [self cacheFileNameForCategory:category country:country];
	if (!cacheFile || ![self.fileManager fileExistsAtPath:cacheFile]) {
		return;
	}
	NSError *error = nil;
	if (![self.fileManager removeItemAtPath:cacheFile error:&error]) {
		NSLog(@"Unable to remove cache file '%@', error = %@", cacheFile, [error localizedDescription]);
	}
}

- (void)emptyCache 
{
    NSString *cacheDir = [self applicationCacheDirectory];
    [self.fileManager removeItemAtPath:cacheDir error:NULL];
}

@end
