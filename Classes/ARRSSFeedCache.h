/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "ARCategoryTuple.h"


@interface ARRSSFeedCache : NSObject

+ (ARRSSFeedCache *)sharedARRSSFeedCache;
+ (NSTimeInterval)expiryInterval;

- (NSData *)retrieveCachedFeedForCategory:(ARCategoryTuple *)category country:(NSString *)country expiryDate:(NSDate **)expiryDate;
- (void)cacheFeed:(NSData *)feedData forCategory:(ARCategoryTuple *)category country:(NSString *)country;
- (void)removeCachedFeedForCategory:(ARCategoryTuple *)category country:(NSString *)country;
- (void)emptyCache;

@end
