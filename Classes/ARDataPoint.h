/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Foundation/Foundation.h>

@interface ARDataPoint : NSObject

@property CGFloat x;
@property CGFloat y;

- (id)initWithX:(CGFloat)x y:(CGFloat)y;

@end
