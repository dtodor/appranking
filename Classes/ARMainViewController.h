/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "ARStatusViewController.h"
#import "ARAppDetailsWindowController.h"
#import "ARChartViewController.h"


@interface ARMainViewController : NSViewController <NSOutlineViewDelegate, NSSplitViewDelegate>

- (void)reloadApplications;

@end
