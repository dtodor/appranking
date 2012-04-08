/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>


@interface ARGoogleChart : NSObject

@property (nonatomic, readonly, strong) NSDate *startDate;
@property (nonatomic, readonly, strong) NSDate *endDate;

- (id)initWithEntries:(NSArray *)entries sorted:(BOOL)sorted;
+ (id)chartForEntries:(NSArray *)entries sorted:(BOOL)sorted;

- (NSURLRequest *)URLRequest;
- (NSImage *)image;

@end
