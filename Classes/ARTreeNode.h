/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "ARCategoryTuple.h"
#import "ARApplication.h"

@interface ARTreeNode : NSTreeNode

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSImage *icon;
@property (nonatomic) NSUInteger badge;
@property (nonatomic) BOOL displaysBadge;
@property (nonatomic, strong) ARCategoryTuple *category;
@property (nonatomic, strong) ARApplication *application;

@end
