/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "ARApplication.h"


typedef enum {
	DidSaveChanges,
	DidDiscardChanges
} AppDetailsWindowControllerReturnCodes;


@interface ARAppDetailsWindowController : NSWindowController

@property (nonatomic, strong) ARApplication *application;

@end
