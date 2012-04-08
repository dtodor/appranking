/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARStatusViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ARStatusViewController ()

@property (nonatomic, weak) IBOutlet TSPProgressIndicator *progressBar;

@end


@implementation ARStatusViewController

@synthesize mainLabel = _mainLabel;
@synthesize progressBar = _progressBar;
@synthesize secondaryLabel = _secondaryLabel;
@synthesize progress = _progress;

- (void)awakeFromNib 
{
    self.progressBar.maxValue = 1.0;
	self.progressBar.progressColor = [NSColor colorWithDeviceWhite:0.2 alpha:0.9];
	self.progressBar.progressHolderColor = [NSColor colorWithDeviceWhite:0.5 alpha:0.5];
    self.progressBar.usesThreadedAnimation = YES;
}

- (void)updateAppIcon 
{
    NSImage *appIcon = [NSImage imageNamed:@"NSApplicationIcon"];
	if (self.progress > 0) {
		NSImage *badgeOverlay = [[NSImage alloc] initWithSize:NSMakeSize(128, 128)];
		[badgeOverlay lockFocus];
		{
			[self.progressBar drawRect:NSMakeRect(0, 0, 128, 24)];
			[appIcon compositeToPoint:NSZeroPoint operation:NSCompositeDestinationOver];
		}
		[badgeOverlay unlockFocus];
		[NSApp setApplicationIconImage:badgeOverlay];
	} else {
		[NSApp setApplicationIconImage:appIcon];
	}
}

- (void)setProgress:(double)percent 
{
    assert(percent >= 0 && percent <= 1.0);
    _progress = percent;
    [self.progressBar setHidden:(self.progress == 0)];
	if (self.progress > 0) {
		[self.progressBar stopAnimation:nil];
		[self.progressBar setIsIndeterminate:NO];
		self.progressBar.doubleValue = self.progress;
		[self.progressBar setNeedsDisplay:YES];
	}
	[self updateAppIcon];
}

- (void)displayIndeterminateProgress 
{
    [self.progressBar setHidden:NO];
    [self.progressBar setIsIndeterminate:YES];
    [self.progressBar startAnimation:nil];
}

@end
