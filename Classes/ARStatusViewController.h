//
//  ARStatusViewController.h
//  AppRanking
//
//  Created by Todor Dimitrov on 25.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ARStatusViewController : NSViewController {
	NSTextField *mainLabel;
	NSView *progressBar;
}

@property (retain) IBOutlet NSTextField *mainLabel;
@property (retain) IBOutlet NSView *progressBar;

@end
