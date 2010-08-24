//
//  AppRankingAppDelegate.h
//  AppRanking
//
//  Created by Todor Dimitrov on 22.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ARRankQuery.h"


@interface AppRankingAppDelegate : NSObject <NSApplicationDelegate, RankQueryDelegate> {
    NSWindow *window;
	NSTextView *logTextView;
	NSButton *startButton;
	NSProgressIndicator *progressIndicator;
	
	NSMutableArray *runningQueries;
	NSMutableArray *pendingQueries;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet NSTextView *logTextView;
@property (retain) IBOutlet NSButton *startButton;
@property (retain) IBOutlet NSProgressIndicator *progressIndicator;

- (IBAction)start:(NSButton *)sender;

@end
