/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>


@interface ARStochasticRankGenerator : NSObject {
}

- (id)initWithMinRank:(NSUInteger)min maxRank:(NSUInteger)max;
- (NSUInteger)nextRankValue;

@end
