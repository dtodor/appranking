/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARDataPoint.h"

@implementation ARDataPoint

@synthesize x = _x;
@synthesize y = _y;

- (id)initWithX:(CGFloat)x y:(CGFloat)y {
    if (self = [super init]) {
        _x = x;
        _y = y;
    }
    return self;
}

@end
