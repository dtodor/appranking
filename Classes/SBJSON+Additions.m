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


