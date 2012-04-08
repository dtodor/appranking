/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Foundation/Foundation.h>
#import "SBJsonParser.h"


extern NSString * const kSBJSONAdditionsErrorDomain;

typedef enum {
	NotADictinary,
	NotAnArray,
	NotAString,
	NotANumber
} SBJSONAdditionsErrorCodes;


@interface SBJsonParser(SBJSON_Additions)

- (NSDictionary *)dictionaryWithString:(NSString *)jsonText error:(NSError **)error;
- (NSArray *)arrayWithString:(NSString *)jsonText error:(NSError **)error;

@end


@interface NSDictionary(SBJSON_Additions)

- (NSDictionary *)dictionaryForKey:(NSString *)key error:(NSError **)error;
- (NSArray *)arrayForKey:(NSString *)key error:(NSError **)error;
- (NSString *)stringForKey:(NSString *)key error:(NSError **)error;
- (NSNumber *)numberForKey:(NSString *)key error:(NSError **)error;

@end


@interface NSArray(SBJSON_Additions)

- (NSDictionary *)dictionaryAtIndex:(NSUInteger)index error:(NSError **)error;
- (NSArray *)arrayAtIndex:(NSUInteger)index error:(NSError **)error;
- (NSString *)stringAtIndex:(NSUInteger)index error:(NSError **)error;
- (NSNumber *)numberAtIndex:(NSUInteger)index error:(NSError **)error;

@end
