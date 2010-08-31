//
//  NumberValueTransformer.h
//  TestCoreData
//
//  Created by Todor Dimitrov on 28.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AREnumValueTransformer : NSValueTransformer {
	NSArray *valueNames;
}

- (id)initWithValueNames:(NSArray *)names;

@end
