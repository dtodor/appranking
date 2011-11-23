/*
 * Copyright (c) 2011 Todor Dimitrov
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

#import "ARGraphView.h"
#import "ARSeries.h"
#import "ARDataPoint.h"
#import "ARColor.h"

@implementation ARGraphView {
    NSMutableDictionary *_series;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _series = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_series release], _series = nil;
    [super dealloc];
}

- (void)addSeries:(ARSeries *)series forKey:(NSString *)key {
    assert(series);
    assert(key);
    
    [_series setObject:series forKey:key];
    [self setNeedsDisplay:YES];
}

- (void)removeSeriesForKey:(NSString *)key {
    assert(key);
    
    [_series removeObjectForKey:key];
    [self setNeedsDisplay:YES];
}

- (void)clear {
    [_series removeAllObjects];
    [self setNeedsDisplay:YES];
}

- (void)drawSeries:(ARSeries *)series context:(CGContextRef)context bounds:(CGRect)bounds {
    CGContextBeginPath(context);
    CGContextSetStrokeColorWithColor(context, series.color.CGColor);
    [series sort];
    BOOL first = YES;
    for (ARDataPoint *point in series.dataPoints) {
        CGFloat x = bounds.size.width*point.x;
        CGFloat y = bounds.size.height*point.y;
        if (first) {
            first = NO;
            CGContextMoveToPoint(context, x, y);
        } else {
            CGContextAddLineToPoint(context, x, y);
        }
    }
    CGContextStrokePath(context);
}

- (void)drawRect:(NSRect)dirtyRect {
    CGRect bounds = [self bounds];
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetShouldAntialias(context, 1);
    CGContextSetRGBFillColor(context, 0.7, 0.7, 0.7, 1);
    CGContextFillRect(context, bounds);
    CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
    CGContextStrokeRect(context, bounds);
    
    for (NSString *key in _series) {
        ARSeries *series = [_series objectForKey:key];
        [self drawSeries:series context:context bounds:bounds];
    }
}

@end
