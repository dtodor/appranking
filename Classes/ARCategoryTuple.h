/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Foundation/Foundation.h>

typedef enum {
	Top_Free_Apps          = 0,
	Top_Paid_Apps          = 1,
	Top_Grossing_Apps      = 2,
	Top_Free_iPad_Apps     = 3,
	Top_Paid_iPad_Apps     = 4,
	Top_Grossing_iPad_Apps = 5,
	New_Apps			   = 6,
	New_Free_Apps		   = 7,
	New_Paid_Apps		   = 8
} CategoryTupleType;

@interface ARCategoryTuple : NSManagedObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *type;
@property (nonatomic, strong) NSSet *applications;
@property (nonatomic, strong) NSSet *rankEntries;

@property (nonatomic) CategoryTupleType tupleType;

- (NSURL *)rankingURLForCountry:(NSString *)country;
- (NSString *)typeName;

+ (NSArray *)typeNames;

@end
