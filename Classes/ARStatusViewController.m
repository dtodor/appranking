//
//  ARStatusViewController.m
//  AppRanking
//
//  Created by Todor Dimitrov on 25.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import "ARStatusViewController.h"

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

- (void)dealloc {
	self.mainLabel = nil;
	self.progressBar = nil;
	[super dealloc];
}

- (void)awakeFromNib {
	CALayer *layer = [progressBar layer];
	layer.borderWidth = 1.0;
	layer.borderColor = [[NSColor colorWithDeviceWhite:0.3 alpha:0.5] CGColor];
	layer.cornerRadius = 5;
	[layer setMasksToBounds:YES];
	
	CALayer *indicator = [CALayer layer];
	indicator.backgroundColor = [[NSColor colorWithDeviceWhite:0.1 alpha:0.5] CGColor];
	indicator.bounds = CGRectMake(0, 0, layer.bounds.size.width/2, layer.bounds.size.height);
	indicator.position = CGPointMake(0.0, 0.0);
	indicator.anchorPoint = CGPointMake(0.0, 0.0);
	
	[layer addSublayer:indicator];
}

@end
