/*
 * Copyright (c) 2010 Todor Dimitrov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "ARChartImageView.h"


@interface ARChartImageView()

@property (nonatomic, retain) NSWindow *zoomWindow; 

@end


@implementation ARChartImageView

@synthesize image;
@synthesize zoomWindow;

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"image"];
	[image release], image = nil;
	[zoomWindow release], zoomWindow = nil;
	[super dealloc];
}

- (void)awakeFromNib {
	[self addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self setNeedsDisplay:YES];
	[[self window] invalidateCursorRectsForView:self];
}

- (void)drawImage {
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	
	NSSize viewSize  = [self bounds].size;
	NSSize imageSize = [image size];
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

	[image drawInRect:destRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
}

- (void)drawInfoMessage {
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

- (void)drawRect:(NSRect)dirtyRect {
	if (!image) {
		[self drawInfoMessage];
	} else {
		[self drawImage];
	}
}

- (void)resetCursorRects {
    [super resetCursorRects];
	if (image) {
		NSCursor *cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom-cursor"] hotSpot:NSMakePoint(0, 0)];
		[self addCursorRect:[self bounds] cursor:cursor];
		[cursor release];
	}
}

- (void)showChartImageInFullSize {
	NSSize imageSize = [image size];
	self.zoomWindow = [[[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) 
												  styleMask:NSUtilityWindowMask|NSHUDWindowMask|NSResizableWindowMask|NSClosableWindowMask|NSTitledWindowMask 
													backing:NSBackingStoreBuffered 
													  defer:NO] autorelease];
	[zoomWindow setTitle:@"Chart"];
	NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(10, 10, imageSize.width-20, imageSize.height-20)];
	[imageView setImageScaling:NSImageScaleProportionallyUpOrDown];
	[imageView setAutoresizingMask:NSViewMinXMargin|NSViewMaxXMargin|NSViewWidthSizable|NSViewMinYMargin|NSViewMaxYMargin|NSViewHeightSizable];
	[imageView setImage:self.image];
	[[zoomWindow contentView] addSubview:imageView];
	[imageView release];
	[zoomWindow setFrame:NSMakeRect(0, 0, imageSize.width, imageSize.height) display:NO];
	[zoomWindow setDelegate:self];
	[zoomWindow setFrameOrigin:NSMakePoint(imageSize.width/2, imageSize.height/2)];
	[zoomWindow makeKeyAndOrderFront:nil];
}

- (void)windowWillClose:(NSNotification *)notification {
	self.zoomWindow = nil;
}

- (void)mouseUp:(NSEvent *)theEvent {
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
