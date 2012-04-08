/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARSeries.h"
#import "ARDataPoint.h"

@implementation ARSeries

@synthesize dataPoints = _dataPoints;
@synthesize color = _color;

- (id)init 
{
    if (self = [super init]) {
        _dataPoints = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addDataPointForX:(CGFloat)x y:(CGFloat)y 
{
    assert(x >= 0 && x <= 1);
    assert(y >= -1 && y <= 1);
    ARDataPoint *dp = [[ARDataPoint alloc] initWithX:x y:y];
    [(NSMutableArray *)_dataPoints addObject:dp];
}

- (void)clear 
{
    [(NSMutableArray *)_dataPoints removeAllObjects];
}

- (void)sort 
{
    [(NSMutableArray *)_dataPoints sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        ARDataPoint *p1 = (ARDataPoint *)obj1;
        ARDataPoint *p2 = (ARDataPoint *)obj2;
        
        if (p1.x < p2.x) {
            return NSOrderedAscending;
        } else if (p1.x > p2.x) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
}

@end
