/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "ARChartViewControllerDelegate.h"

@class ARSeries;
 
@interface ARGraphView : NSView <ARChartViewControllerDelegate>

- (void)addSeries:(ARSeries *)series forKey:(NSString *)key;
- (void)removeSeriesForKey:(NSString *)key;
- (void)clear;

@end
