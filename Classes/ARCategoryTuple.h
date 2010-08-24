//
//  CategoryTuple.h
//  AppRanking
//
//  Created by Todor Dimitrov on 23.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	Top_Free_Apps,
	Top_Paid_Apps,
	Top_Grossing_Apps,
	Top_Free_iPad_Apps,
	Top_Paid_iPad_Apps,
	Top_Grossing_iPad_Apps
} CategoryTupleType;

@interface ARCategoryTuple : NSObject<NSCopying> {
	NSString *name;
	CategoryTupleType type;
}

@property (readonly) NSString *name;
@property (readonly) CategoryTupleType type;

- (id)initWithName:(NSString *)categoryName type:(CategoryTupleType)tupleType;
- (id)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error;

- (NSURL *)rankingURLForCountry:(NSString *)country;

@end
