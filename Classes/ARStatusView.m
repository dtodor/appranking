//
//  ARStatusView.m
//  AppRanking
//
//  Created by Todor Dimitrov on 25.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import "ARStatusView.h"


@implementation ARStatusView

- (void)drawRect:(NSRect)rect {
	NSImage *left = [NSImage imageNamed:@"status-view-left"];
	NSImage *center = [NSImage imageNamed:@"status-view-center"];
	NSImage *right = [NSImage imageNamed:@"status-view-right"];
	
	NSRect frame = [self frame];
	NSDrawThreePartImage(NSMakeRect(0, 3, frame.size.width, 48), left, center, right, NO, NSCompositeSourceOver, 1.0, NO);
}

@end
