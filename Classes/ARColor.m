/*
 * Copyright (c) 2011 Todor Dimitrov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
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

@synthesize red;
@synthesize green;
@synthesize blue;

- (id)init {
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
		[color getRed:&red green:&green blue:&blue alpha:NULL];
	}
	return self;
}

- (void)dealloc {
    if (_CGColor) {
        CGColorRelease(_CGColor), _CGColor = NULL;
    }
    [super dealloc];
}

- (NSString *)hex {
	return [NSString stringWithFormat:@"%.2X%.2X%.2X", (int)(red*255), (int)(green*255), (int)(blue*255)];
}

- (NSColor *)color {
	return [NSColor colorWithDeviceRed:red green:green blue:blue alpha:1.0];
}

- (CGColorRef)CGColor {
    if (!_CGColor) {
        CGFloat components[4] = {red, green, blue, 1.0};
        CGColorSpaceRef theColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        _CGColor = CGColorCreate(theColorSpace, components);
        CGColorSpaceRelease(theColorSpace);
    }
    return _CGColor;
}

+ (ARColor *)randomColor {
	return [[[ARColor alloc] init] autorelease];
}

+ (ARColor *)colorForCountry:(NSString *)country {
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
