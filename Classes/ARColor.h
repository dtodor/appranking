/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>


@interface ARColor : NSObject

@property (nonatomic, readonly) CGFloat red;
@property (nonatomic, readonly) CGFloat green;
@property (nonatomic, readonly) CGFloat blue;

@property (readonly) NSString *hex;
@property (readonly) NSColor *color;
@property (readonly) CGColorRef CGColor;

+ (ARColor *)randomColor;
+ (ARColor *)colorForCountry:(NSString *)country;

@end
