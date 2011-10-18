/*
 * Copyright (c) 2010 Todor Dimitrov
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

#import "ARCategoryTuple.h"
#import "ARConfiguration.h"
#import "ARConfiguration.h"


static NSString * const kFeedURLTemplate_SelectedCategory = @"http://itunes.apple.com/%@/rss/%@/limit=300/genre=%@/json";
static NSString * const kFeedURLTemplate_All = @"http://itunes.apple.com/%@/rss/%@/limit=300/json";


@implementation ARCategoryTuple

@dynamic name;
@dynamic type;
@dynamic applications;
@dynamic rankEntries;

- (CategoryTupleType)tupleType {
	return (CategoryTupleType)[self.type intValue];
}

- (void)setTupleType:(CategoryTupleType)type_ {
	self.type = [NSNumber numberWithInt:type_];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ (%@)", (self.name?self.name:@"All"), [self typeName]];
}

- (NSComparisonResult)compare:(ARCategoryTuple *)otherTuple {
	NSComparisonResult result;
	if (self.name && !otherTuple.name) {
		result = NSOrderedDescending;
	} else if (!self.name && otherTuple.name) {
		result = NSOrderedAscending;
	} else {
		result = [self.name compare:otherTuple.name];
	}
	if (result == NSOrderedSame) {
		result = [self.type compare:otherTuple.type];
	}
	return result;

}

- (NSURL *)rankingURLForCountry:(NSString *)country {
	ARConfiguration *config = [ARConfiguration sharedARConfiguration];
	NSString *countryCode = [config.countries objectForKey:country];
	if (!countryCode) {
		return nil;
	}

	NSString *typeName = [self typeName];
	NSString *urlPart = [NSString stringWithFormat:@"%@applications", [[typeName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString]];

	if (self.name) {
		NSString *ganreId = [config.genres objectForKey:self.name];
		if (!ganreId) {
			return nil;
		}
		return [NSURL URLWithString:[NSString stringWithFormat:kFeedURLTemplate_SelectedCategory, countryCode, urlPart, ganreId]];
	} else {
		return [NSURL URLWithString:[NSString stringWithFormat:kFeedURLTemplate_All, countryCode, urlPart]];
	}
}

- (NSString *)typeName {
	if (self.type) {
		return [[ARCategoryTuple typeNames] objectAtIndex:[self.type intValue]];
	} else {
		return nil;
	}
}

+ (NSArray *)typeNames {
	static NSArray *typeNames = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		typeNames = [[NSArray alloc] initWithObjects:@"Top Free", @"Top Paid", 
					 @"Top Grossing", @"Top Free iPad", @"Top Paid iPad", 
					 @"Top Grossing iPad", @"New", @"New Free", 
					 @"New Paid", nil];
	});
	return typeNames;
}

- (BOOL)validateName:(id *)value error:(NSError **)error {
	if (*value == nil) {
		return YES;
	}
	NSString *nameStr = *value;
	ARConfiguration *config = [ARConfiguration sharedARConfiguration];
	if (![config.genres objectForKey:nameStr]) {
		if (error) {
			*error = [NSError errorWithDomain:@"ARCategoryTuple" 
										 code:0 
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"'%@' is not a valid category", nameStr] 
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return NO;
	} else {
		return YES;
	}
}

@end
