/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARChartImageView.h"
#import "ARChartViewController.h"
#import "ARGoogleChart.h"


@interface ARChartImageView() <NSWindowDelegate>

@property (nonatomic, strong) NSWindow *zoomWindow; 

@end


@implementation ARChartImageView

@synthesize image = _image;
@synthesize zoomWindow = _zoomWindow;

- (void)chartViewController:(ARChartViewController *)controller didUpdateData:(NSArray *)data sorted:(BOOL)sorted 
{
    if ([data count] > 1) {
        ARGoogleChart *chart = [ARGoogleChart chartForEntries:data sorted:sorted];
        self.image = chart.image;
    } else {
        self.image = nil;
    }
}

- (void)dealloc 
{
	[self removeObserver:self forKeyPath:@"image"];
}

- (void)awakeFromNib 
{
	[self addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
	[self setNeedsDisplay:YES];
	[[self window] invalidateCursorRectsForView:self];
}

- (void)drawImage 
{
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	
	NSSize viewSize  = [self bounds].size;
	NSSize imageSize = [self.image size];
	CGFloat ratio = imageSize.width/imageSize.height;
	
	CGFloat imageWidth = 0;
	CGFloat imageHeight = 0;
	if (imageSize.width >= viewSize.width && imageSize.height <= viewSize.height) {
		imageWidth = viewSize.width;
	} else if (imageSize.width <= viewSize.width && imageSize.height >= viewSize.height) {
		imageHeight = viewSize.height;
	} else if ((imageSize.width <= viewSize.width && imageSize.height <= viewSize.height) ||
			   (imageSize.width >= viewSize.width && imageSize.height >= viewSize.height)) {
		
		CGFloat viewRatio = viewSize.width/viewSize.height;
		if (ratio > viewRatio) {
			imageWidth = viewSize.width;
		} else {
			imageHeight = viewSize.height;
		}
	}
	
	if (imageWidth > 0) {
		imageHeight = imageWidth/ratio;
	} else {
		imageWidth = imageHeight*ratio;
	}
	
	imageSize = NSMakeSize(imageWidth, imageHeight);
	
	NSPoint viewCenter;
	viewCenter.x = viewSize.width  * 0.50;
	viewCenter.y = viewSize.height * 0.50;
	
	NSPoint imageOrigin = viewCenter;
	imageOrigin.x -= imageSize.width  * 0.50;
	imageOrigin.y -= imageSize.height * 0.50;
	
	NSRect destRect;
	destRect.origin = imageOrigin;
	destRect.size = imageSize;
	destRect = NSInsetRect(destRect, 5, 5);
	
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    CGContextSetShadow(context, CGSizeMake(0, 0), 5); 

    [[NSColor whiteColor] set];
	NSRectFill(destRect);
    CGContextRestoreGState(context);

	[self.image drawInRect:destRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
}

- (void)drawInfoMessage 
{
	NSRect bounds = [self bounds];
	
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    CGContextSetShadow(context, CGSizeMake(0, 0), 5); 

    [[NSColor whiteColor] set];
	NSRectFill(NSInsetRect(bounds, 5, 5));
    
    CGContextRestoreGState(context);
	
	[[NSColor blackColor] set];
	NSString *displayString = @"No data available";
	NSFont *displayFont = [NSFont systemFontOfSize:16];
	NSDictionary *displayAttributes = [NSDictionary dictionaryWithObject:displayFont forKey:NSFontAttributeName];
	NSSize textSize = [displayString sizeWithAttributes:displayAttributes];
	NSPoint textPosition;
	textPosition.x = (bounds.size.width / 2) - (textSize.width / 2);
	textPosition.y = (bounds.size.height / 2) - (textSize.height / 2);
	[displayString drawAtPoint:textPosition withAttributes:displayAttributes];
}

- (void)drawRect:(NSRect)dirtyRect 
{
	if (!self.image) {
		[self drawInfoMessage];
	} else {
		[self drawImage];
	}
}

- (void)resetCursorRects 
{
    [super resetCursorRects];
	if (self.image) {
		NSCursor *cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom-cursor"] hotSpot:NSMakePoint(0, 0)];
		[self addCursorRect:[self bounds] cursor:cursor];
	}
}

- (void)showChartImageInFullSize 
{
	NSSize imageSize = [self.image size];
	self.zoomWindow = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) 
												  styleMask:NSUtilityWindowMask|NSHUDWindowMask|NSResizableWindowMask|NSClosableWindowMask|NSTitledWindowMask 
													backing:NSBackingStoreBuffered 
													  defer:NO];
	[self.zoomWindow setTitle:@"Chart"];
	NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(10, 10, imageSize.width-20, imageSize.height-20)];
	[imageView setImageScaling:NSImageScaleProportionallyUpOrDown];
	[imageView setAutoresizingMask:NSViewMinXMargin|NSViewMaxXMargin|NSViewWidthSizable|NSViewMinYMargin|NSViewMaxYMargin|NSViewHeightSizable];
	[imageView setImage:self.image];
	[[self.zoomWindow contentView] addSubview:imageView];
	[self.zoomWindow setFrame:NSMakeRect(0, 0, imageSize.width, imageSize.height) display:NO];
	[self.zoomWindow setDelegate:self];
	[self.zoomWindow setFrameOrigin:NSMakePoint(imageSize.width/2, imageSize.height/2)];
	[self.zoomWindow makeKeyAndOrderFront:nil];
}

- (void)windowWillClose:(NSNotification *)notification 
{
	self.zoomWindow = nil;
}

- (void)mouseUp:(NSEvent *)theEvent 
{
	if (!self.image) {
		return;
	}
	NSPoint eventLocation = [theEvent locationInWindow];
	NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];
	NSSize size = [self bounds].size;
	if (localPoint.x < 0 || localPoint.x > size.width || localPoint.y < 0 || localPoint.y > size.height) {
		NSLog(@"Mouse up outside");
	} else {
		NSLog(@"Mouse up inside");
		[self showChartImageInFullSize];
	}
}

@end
