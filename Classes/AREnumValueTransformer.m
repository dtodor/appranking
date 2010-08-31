//
//  NumberValueTransformer.m
//  TestCoreData
//
//  Created by Todor Dimitrov on 28.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import "AREnumValueTransformer.h"


@implementation AREnumValueTransformer

- (id)initWithValueNames:(NSArray *)names {
	if (self = [super init]) {
		assert([names count] > 0);
		valueNames = [names retain];
	}
	return self;
}

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)reverseTransformedValue:(id)value {
    if (value == nil) return nil;
    if (![value isKindOfClass:[NSString class]]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Value (%@) is not a string", [value class]];
    }
	NSUInteger index = [valueNames indexOfObject:value];
	assert(index != NSNotFound);
	return [NSNumber numberWithUnsignedInteger:index];
}

- (id)transformedValue:(id)value {
    if (value == nil) return nil;
	if (![value isKindOfClass:[NSNumber class]]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Value (%@) is not a number", [value class]];
	}
	NSUInteger index = [value unsignedIntegerValue];
	assert(index < [valueNames count]);
	return [valueNames objectAtIndex:index];
}

@end
