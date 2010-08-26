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

#import "ARStatusViewController.h"
#import <QuartzCore/QuartzCore.h>


@interface NSColor(CGColor)

- (CGColorRef)CGColor;

@end


@implementation NSColor(CGColor)

- (CGColorRef)CGColor {
    CGColorSpaceRef colorSpace = [[self colorSpace] CGColorSpace];
    NSInteger componentCount = [self numberOfComponents];
    CGFloat *components = (CGFloat *)calloc(componentCount, sizeof(CGFloat));
    [self getComponents:components];
    CGColorRef color = CGColorCreate(colorSpace, components);
    free((void*)components);
    return color;
}

@end


@implementation ARStatusViewController

@synthesize mainLabel;
@synthesize progressBar;
@synthesize secondaryLabel;

- (void)dealloc {
	self.mainLabel = nil;
	self.secondaryLabel = nil;
	self.progressBar = nil;
	[super dealloc];
}

- (void)awakeFromNib {
	CALayer *layer = [progressBar layer];
	if (!layer || [[layer sublayers] count] > 0) {
		return;
	}
	layer.delegate = self;
	layer.borderWidth = 1.0;
	layer.borderColor = [[NSColor colorWithDeviceWhite:0.3 alpha:0.5] CGColor];
	layer.cornerRadius = 5;
	layer.opacity = 0.0;
	[layer setMasksToBounds:YES];
	
	CALayer *indicator = [CALayer layer];
	indicator.backgroundColor = [[NSColor colorWithDeviceWhite:0.1 alpha:0.5] CGColor];
	indicator.bounds = CGRectMake(0, 0, 0, layer.bounds.size.height);
	indicator.position = CGPointMake(0.0, 0.0);
	indicator.anchorPoint = CGPointMake(0.0, 0.0);
	
	[layer addSublayer:indicator];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
	CALayer *indicator = [[layer sublayers] objectAtIndex:0];
	[CATransaction begin];
	if (progressPercent == 0.0) {
		[CATransaction setDisableActions:YES];
	}
	indicator.bounds = CGRectMake(0, 0, progressPercent*layer.bounds.size.width, layer.bounds.size.height);
	[CATransaction commit];
	layer.opacity = (progressPercent == 0.0)?0.0:1.0;
}

- (void)setProgress:(double)percent {
	assert(percent >= 0 && percent <= 100.0);
	progressPercent = percent;
	[[progressBar layer] setNeedsLayout];
}

@end
