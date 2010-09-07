//
//  ARTempCategoryTuple.h
//  AppRanking
//
//  Created by Todor Dimitrov on 31.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ARCategoryTuple.h"


@interface ARTempCategoryTuple : NSObject {
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *type;

- (BOOL)validate:(NSError **)error;
- (BOOL)fetchCorrespondingCategory:(ARCategoryTuple **)category error:(NSError **)error;

@end
