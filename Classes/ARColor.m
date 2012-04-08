/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARColor.h"

/*
 * Random color generation done using a method presented by Martin Ankerl:
 * http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
 */

@implementation ARColor {
    CGColorRef _CGColor;
}

#define MAX_RANDOM 0x100000000
#define RANDOM ((double)(arc4random()%(MAX_RANDOM+1))/MAX_RANDOM)
#define GOLDEN_RATIO_CONJUGATE 0.618033988749895

@synthesize red = _red;
@synthesize green = _green;
@synthesize blue = _blue;

- (id)init 
{
	self = [super init];
	if (self != nil) {
		static CGFloat h;
		static dispatch_once_t once;
		dispatch_once(&once, ^{
			h = RANDOM;
		});
		h += GOLDEN_RATIO_CONJUGATE;
		if (h > 1) h -= 1;
		NSColor *color = [NSColor colorWithDeviceHue:h saturation:0.75 brightness:0.85 alpha:1.0];
		[color getRed:&_red green:&_green blue:&_blue alpha:NULL];
	}
	return self;
}

- (void)dealloc 
{
    if (_CGColor) {
        CGColorRelease(_CGColor), _CGColor = NULL;
    }
}

- (NSString *)hex 
{
	return [NSString stringWithFormat:@"%.2X%.2X%.2X", (int)(_red*255), (int)(_green*255), (int)(_blue*255)];
}

- (NSColor *)color 
{
	return [NSColor colorWithDeviceRed:_red green:_green blue:_blue alpha:1.0];
}

- (CGColorRef)CGColor 
{
    if (!_CGColor) {
        CGFloat components[4] = {_red, _green, _blue, 1.0};
        CGColorSpaceRef theColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        _CGColor = CGColorCreate(theColorSpace, components);
        CGColorSpaceRelease(theColorSpace);
    }
    return _CGColor;
}

+ (ARColor *)randomColor 
{
	return [[ARColor alloc] init];
}

+ (ARColor *)colorForCountry:(NSString *)country 
{
	static NSMutableDictionary *cache;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		cache = [[NSMutableDictionary alloc] init];
	});
	assert(country);
	
	ARColor *color = [cache objectForKey:country];
	if (!color) {
		color = [[self class] randomColor];
		[cache setObject:color forKey:country];
	}
	return color;
}

@end
