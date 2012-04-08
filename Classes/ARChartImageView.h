/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "ARChartViewControllerDelegate.h"

@interface ARChartImageView : NSView <ARChartViewControllerDelegate>

@property (nonatomic, strong) NSImage *image;

@end
