/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "TSPProgressIndicator.h"


@interface ARStatusViewController : NSViewController

@property (nonatomic, weak) IBOutlet NSTextField *mainLabel;
@property (nonatomic, weak) IBOutlet NSTextField *secondaryLabel;
@property (nonatomic) double progress;

- (void)displayIndeterminateProgress;

@end
