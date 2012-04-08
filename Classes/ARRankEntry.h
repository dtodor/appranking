/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "ARApplication.h"
#import "ARCategoryTuple.h"


@interface ARRankEntry : NSManagedObject

@property (nonatomic, strong) ARApplication *application;
@property (nonatomic, strong) ARCategoryTuple *category;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSNumber *rank;
@property (nonatomic, strong) NSDate *timestamp;

@end
