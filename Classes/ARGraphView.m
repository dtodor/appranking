/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARGraphView.h"
#import "ARSeries.h"
#import "ARDataPoint.h"
#import "ARColor.h"
#import "ARRankEntry.h"

#define NSStringFromCGRect(rect) [NSString stringWithFormat:@"[%f, %f, %f, %f]", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height]

@implementation ARGraphView {
    NSMutableDictionary *_series;
    CGRect _cursorBounds;
}

- (void)chartViewController:(ARChartViewController *)controller didUpdateData:(NSArray *)data sorted:(BOOL)sorted 
{
    [self clear];
    if ([data count] < 2) {
        return;
    }
    NSArray *sortedEntries;
    if (!sorted) {
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" 
                                                                                          ascending:YES]];
        sortedEntries = [data sortedArrayUsingDescriptors:sortDescriptors];
    } else {
        sortedEntries = data;
    }
    NSDate *startDate = ((ARRankEntry *)[sortedEntries objectAtIndex:0]).timestamp;
    NSDate *endDate = ((ARRankEntry *)[sortedEntries lastObject]).timestamp;
    
    assert(startDate);
    assert(endDate);
    assert([startDate isLessThan:endDate]);
    
    NSTimeInterval timeSpan = [endDate timeIntervalSinceDate:startDate];
	NSMutableDictionary *country2entries = [NSMutableDictionary dictionary];
	for (ARRankEntry *entry in sortedEntries) {
		NSMutableArray *data = [country2entries objectForKey:entry.country];
		if (!data) {
			data = [NSMutableArray array];
			[country2entries setObject:data forKey:entry.country];
		}
		[data addObject:entry];
	}
    
	for (NSString *country in country2entries) {
		NSArray *entriesForCountry = [country2entries objectForKey:country];
		ARSeries *series = [[ARSeries alloc] init];
		for (ARRankEntry *entry in entriesForCountry) {
			double timeValue = [entry.timestamp timeIntervalSinceDate:startDate]/timeSpan;
			static double maxValue = 300.0;
            double rankValue = (maxValue - [entry.rank doubleValue])/maxValue;
            [series addDataPointForX:timeValue y:rankValue];
		}
        series.color = [ARColor colorForCountry:country];
        [self addSeries:series forKey:country];
	}
    
    [self setNeedsDisplay:YES];
}

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
        _series = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addSeries:(ARSeries *)series forKey:(NSString *)key 
{
    assert(series);
    assert(key);
    
    [_series setObject:series forKey:key];
    [self setNeedsDisplay:YES];
}

- (void)removeSeriesForKey:(NSString *)key 
{
    assert(key);
    
    [_series removeObjectForKey:key];
    [self setNeedsDisplay:YES];
}

- (void)clear 
{
    [_series removeAllObjects];
    [self setNeedsDisplay:YES];
}

- (void)drawSeries:(ARSeries *)series context:(CGContextRef)context bounds:(CGRect)bounds 
{
    CGContextSetShouldAntialias(context, true);
    CGContextBeginPath(context);
    BOOL first = YES;
    for (ARDataPoint *point in series.dataPoints) {
        CGFloat x = bounds.size.width*point.x + bounds.origin.x;
        CGFloat y = bounds.size.height*point.y + bounds.origin.y;
        if (first) {
            first = NO;
            CGContextMoveToPoint(context, x, y);
        } else {
            CGContextAddLineToPoint(context, x, y);
        }
    }
    CGContextSetStrokeColorWithColor(context, series.color.CGColor);
    CGContextSetLineWidth(context, 2.0);
    CGContextStrokePath(context);
}

- (CGFloat)widthOfString:(NSString *)str inContext:(CGContextRef)context 
{
    CGFloat start = CGContextGetTextPosition(context).x;
    CGContextSaveGState(context);
    CGContextSetTextDrawingMode(context, kCGTextInvisible);
    CGContextShowText(context, [str cStringUsingEncoding:NSMacOSRomanStringEncoding], [str lengthOfBytesUsingEncoding:NSMacOSRomanStringEncoding]);
    CGFloat width = CGContextGetTextPosition(context).x - start;
    CGContextRestoreGState(context);
    return width;
}

- (CGRect)drawAxes:(CGContextRef)context bounds:(CGRect)bounds 
{
    CGContextSetShouldAntialias(context, false);

    NSUInteger numberOflines = 10;
    CGFloat paddingBottom = bounds.origin.y+35;
    CGFloat paddingTop = 25;
    CGFloat paddingLeft = bounds.origin.x+60;
    CGFloat paddingRight = 30;
    NSUInteger distance = (bounds.size.height - (paddingBottom + paddingTop)) / numberOflines;
    NSUInteger remainder = bounds.size.height - (numberOflines*distance + paddingBottom + paddingTop);
    paddingBottom += remainder - remainder/2;
    paddingTop += remainder/2;
    
    CGContextBeginPath(context);
    
    for (NSUInteger i=1; i<=numberOflines; i++) {
        CGContextMoveToPoint(context, paddingLeft, paddingBottom+i*distance);
        CGContextAddLineToPoint(context, bounds.size.width-paddingRight, paddingBottom+i*distance);
    }
    
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 1.0);
    CGFloat lengths[] = {5};
    CGContextSetLineDash(context, 0, lengths, 1);
    CGContextSetRGBStrokeColor(context, 0.8, 0.8, 0.8, 1);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);

    CGContextBeginPath(context);
    CGContextMoveToPoint(context, paddingLeft, paddingBottom);
    CGContextAddLineToPoint(context, paddingLeft, bounds.size.height-paddingTop);

    CGContextMoveToPoint(context, paddingLeft, paddingBottom);
    CGContextAddLineToPoint(context, bounds.size.width-paddingRight, paddingBottom);
    
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 1.0);
    CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, true);
    CGContextSelectFont(context, "Helvetica", 12.0, kCGEncodingMacRoman);
    
    for (NSUInteger i=0; i<=numberOflines; i++) {
        NSUInteger value = 300-i*(300/numberOflines);
        if (value == 0) value = 1;
        NSString *label = [NSString stringWithFormat:@"%ld", value];
        CGFloat labelWidth = [self widthOfString:label inContext:context];
        CGContextSetTextDrawingMode(context, kCGTextFill);
        CGContextShowTextAtPoint(context, paddingLeft-5-labelWidth, paddingBottom-4.0+i*distance, 
                                 [label cStringUsingEncoding:NSMacOSRomanStringEncoding], 
                                 [label lengthOfBytesUsingEncoding:NSMacOSRomanStringEncoding]);
    }
    
    CGContextRestoreGState(context);
    
    return CGRectMake(paddingLeft, paddingBottom, bounds.size.width-paddingLeft-paddingRight, bounds.size.height-paddingBottom-paddingTop);
}

- (void)drawBackbround:(CGContextRef)context bounds:(CGRect)bounds 
{
    CGContextSaveGState(context);
    CGContextSetShadow(context, CGSizeMake(0, 0), 5); 

    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    CGContextFillRect(context, bounds);

    CGContextRestoreGState(context);
}

- (CGContextRef)contextForBounds:(CGRect)bounds isBitmap:(BOOL *)bitmap trueBounds:(CGRect *)trueBounds 
{
    CGContextRef context = NULL;
    static int minWidth = 500;
    static int minHeight = 300;
    if (bounds.size.width < minWidth || bounds.size.height < minHeight) {
        if (bitmap) {
            *bitmap = YES;
        }
        if (trueBounds) {
            *trueBounds = CGRectMake(0, 0, minWidth, minHeight);
        }

        int bitmapBytesPerRow = minWidth * 4;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        CGContextRef _context = CGBitmapContextCreate(NULL, minWidth, minHeight, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpace);
        if (_context == NULL)         {
            fprintf(stderr, "Could not create bitmal graphics context!");
        } else {
            context = (__bridge CGContextRef)CFBridgingRelease(_context);
        }
    } else {
        context = [[NSGraphicsContext currentContext] graphicsPort];
        
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);    
        
        if (bitmap) {
            *bitmap = NO;
        }
        if (trueBounds) {
            *trueBounds = bounds;
        }
    }
    return context;
}

- (void)drawRect:(NSRect)dirtyRect 
{
    CGRect trueBounds;
    BOOL isBitmap;
    CGContextRef context = [self contextForBounds:[self bounds] isBitmap:&isBitmap trueBounds:&trueBounds];
    if (context == NULL) {
        return;
    }
    
    CGRect insetBounds = CGRectInset(trueBounds, 5, 5);
    [self drawBackbround:context bounds:insetBounds];
    CGRect graphBounds = [self drawAxes:context bounds:insetBounds];
    
    for (NSString *key in _series) {
        ARSeries *series = [_series objectForKey:key];
        [self drawSeries:series context:context bounds:graphBounds];
    }
    
    if (isBitmap) {
        CGImageRef image = CGBitmapContextCreateImage(context);
        CGContextRef viewContext = [[NSGraphicsContext currentContext] graphicsPort];
        CGFloat scale = trueBounds.size.width / self.bounds.size.width;
        if (trueBounds.size.height/scale > self.bounds.size.height) {
            scale = trueBounds.size.height / self.bounds.size.height;
        }
        CGFloat width = trueBounds.size.width/scale;
        CGFloat height = trueBounds.size.height/scale;
        CGRect bounds = CGRectMake((self.bounds.size.width-width)/2, (self.bounds.size.height-height)/2, width, height);
        CGContextSetInterpolationQuality(viewContext, kCGInterpolationHigh);
        CGContextDrawImage(viewContext, bounds, image);
        CGImageRelease(image);
        
        _cursorBounds = bounds;
        [self.window invalidateCursorRectsForView:self];
    } else {
        _cursorBounds = [self bounds];
    }
}

- (void)resetCursorRects 
{
    NSCursor *cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom-cursor"] hotSpot:NSMakePoint(0, 0)];
    [self addCursorRect:_cursorBounds cursor:cursor];
}

@end
