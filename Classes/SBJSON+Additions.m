//
//  SBJSONParser+Additions.m
//  AppRanking
//
//  Created by Todor Dimitrov on 23.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import "SBJSON+Additions.h"


NSString * const kSBJSONAdditionsErrorDomain = @"SBJSONAdditionsErrorDomain";


@implementation SBJsonParser(SBJSON_Additions)

- (NSDictionary *)dictionaryWithString:(NSString *)jsonText error:(NSError **)error {
	id object = [self objectWithString:jsonText error:error];
	if (!object) {
		return nil;
	}
	if (![object isKindOfClass:[NSDictionary class]]) {
		if (error) {
			*error = [NSError errorWithDomain:kSBJSONAdditionsErrorDomain 
										 code:NotADictinary 
									 userInfo:[NSDictionary dictionaryWithObject:@"JSON text is not a dictionary" forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
	return (NSDictionary *)object;
}

- (NSArray *)arrayWithString:(NSString *)jsonText error:(NSError **)error {
	id object = [self objectWithString:jsonText error:error];
	if (!object) {
		return nil;
	}
	if (![object isKindOfClass:[NSArray class]]) {
		if (error) {
			*error = [NSError errorWithDomain:kSBJSONAdditionsErrorDomain 
										 code:NotAnArray 
									 userInfo:[NSDictionary dictionaryWithObject:@"JSON text is not an array" forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
	return (NSArray *)object;
}

@end


@implementation NSDictionary(SBJSON_Additions)

- (NSDictionary *)dictionaryForKey:(NSString *)key error:(NSError **)error {
	id value = [self objectForKey:key];
	if (!value) {
		return nil;
	}
	if (![value isKindOfClass:[NSDictionary class]]) {
		if (error) {
			*error = [NSError errorWithDomain:kSBJSONAdditionsErrorDomain 
										 code:NotADictinary 
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Value stored for key '%@' is not a dictionary", key] 
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
	return (NSDictionary *)value;
}

- (NSArray *)arrayForKey:(NSString *)key error:(NSError **)error {
	id value = [self objectForKey:key];
	if (!value) {
		return nil;
	}
	if (![value isKindOfClass:[NSArray class]]) {
		if (error) {
			*error = [NSError errorWithDomain:kSBJSONAdditionsErrorDomain 
										 code:NotAnArray 
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Value stored for key '%@' is not an array", key] 
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
	return (NSArray *)value;
}

- (NSString *)stringForKey:(NSString *)key error:(NSError **)error {
	id value = [self objectForKey:key];
	if (!value) {
		return nil;
	}
	if (![value isKindOfClass:[NSString class]]) {
		if (error) {
			*error = [NSError errorWithDomain:kSBJSONAdditionsErrorDomain 
										 code:NotAString 
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Value stored for key '%@' is not a string", key] 
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
	return (NSString *)value;
}

- (NSNumber *)numberForKey:(NSString *)key error:(NSError **)error {
	id value = [self objectForKey:key];
	if (!value) {
		return nil;
	}
	if (![value isKindOfClass:[NSNumber class]]) {
		if (error) {
			*error = [NSError errorWithDomain:kSBJSONAdditionsErrorDomain 
										 code:NotANumber
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Value stored for key '%@' is not a number", key] 
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
	return (NSNumber *)value;
}

@end


@implementation NSArray(SBJSON_Additions)

- (NSDictionary *)dictionaryAtIndex:(NSUInteger)index error:(NSError **)error {
	id value = [self objectAtIndex:index];
	if (![value isKindOfClass:[NSDictionary class]]) {
		if (error) {
			*error = [NSError errorWithDomain:kSBJSONAdditionsErrorDomain 
										 code:NotADictinary
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Value at index '%d' is not a dictionary", index] 
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
	return (NSDictionary *)value;
}

- (NSArray *)arrayAtIndex:(NSUInteger)index error:(NSError **)error {
	id value = [self objectAtIndex:index];
	if (![value isKindOfClass:[NSArray class]]) {
		if (error) {
			*error = [NSError errorWithDomain:kSBJSONAdditionsErrorDomain 
										 code:NotAnArray
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Value at index '%d' is not an array", index] 
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
	return (NSArray *)value;
}

- (NSString *)stringAtIndex:(NSUInteger)index error:(NSError **)error {
	id value = [self objectAtIndex:index];
	if (![value isKindOfClass:[NSString class]]) {
		if (error) {
			*error = [NSError errorWithDomain:kSBJSONAdditionsErrorDomain 
										 code:NotAString
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Value at index '%d' is not a string", index] 
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
	return (NSString *)value;
}

- (NSNumber *)numberAtIndex:(NSUInteger)index error:(NSError **)error {
	id value = [self objectAtIndex:index];
	if (![value isKindOfClass:[NSNumber class]]) {
		if (error) {
			*error = [NSError errorWithDomain:kSBJSONAdditionsErrorDomain 
										 code:NotANumber
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Value at index '%d' is not a number", index] 
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
	return (NSNumber *)value;
}

@end


