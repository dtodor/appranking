//
//  Application.h
//  AppRanking
//
//  Created by Todor Dimitrov on 24.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ARCategoryTuple.h"


@interface ARApplication : NSObject {
	NSString *name;
	NSMutableSet *categories;
}

@property (readonly) NSString *name;
@property (readonly) NSSet *categories;

- (id)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error;

@end
