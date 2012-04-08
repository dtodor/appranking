/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Foundation/Foundation.h>

@class ARColor;

@interface ARSeries : NSObject

@property (strong, readonly) NSArray *dataPoints;
@property (strong) ARColor *color;

- (void)addDataPointForX:(CGFloat)x y:(CGFloat)y;
- (void)clear;
- (void)sort;

@end
