/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "ARCategoryTuple.h"


@interface ARApplication : NSManagedObject

@property (nonatomic, strong) NSNumber *appStoreId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSSet *categories;
@property (nonatomic, strong) NSData *iconData;
@property (nonatomic, strong) NSSet *rankEntries;

@property (nonatomic, strong) NSImage *iconImage;

@end
