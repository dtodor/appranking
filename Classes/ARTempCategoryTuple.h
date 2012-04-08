/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "ARCategoryTuple.h"


@interface ARTempCategoryTuple : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *type;

- (BOOL)validate:(NSError **)error;
- (BOOL)fetchCorrespondingCategory:(ARCategoryTuple **)category error:(NSError **)error;

@end
