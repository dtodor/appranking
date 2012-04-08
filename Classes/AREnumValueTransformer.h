/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>


@interface AREnumValueTransformer : NSValueTransformer

@property (nonatomic, copy) NSArray *valueNames;

- (id)initWithValueNames:(NSArray *)names;

@end
