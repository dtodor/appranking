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

#import "ARApplication.h"
#import "SBJSON+Additions.h"


@implementation ARApplication

@synthesize name, categories, icon;

- (NSError *)errorForUnderlyingError:(NSError *)error {
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:@"Unable to create application from dictionary" forKey:NSLocalizedDescriptionKey];
	if (error) {
		[userInfo setObject:error forKey:NSUnderlyingErrorKey];
	}
	return [NSError errorWithDomain:@"ApplicationErrorDomain" code:0 userInfo:userInfo];
}

- (id)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
	self = [super init];
	if (self) {
		NSError *underlyingError = nil;

		NSString *appName = [dictionary stringForKey:@"name" error:&underlyingError];
		if (underlyingError) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			[self release];
			self = nil;
			return self;
		}
		if (!appName) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			[self release];
			self = nil;
			return self;
		}
		name = [appName copy];
		NSArray *tuples = [dictionary arrayForKey:@"tuples" error:&underlyingError];
		if (underlyingError) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			[self release];
			self = nil;
			return self;
		}
		if ([tuples count] == 0) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			[self release];
			self = nil;
			return self;
		}
		categories = [NSMutableSet set];
		for (int j=0; j<[tuples count]; j++) {
			NSDictionary *tuple = [tuples dictionaryAtIndex:j error:&underlyingError];
			if (underlyingError) {
				if (error) {
					*error = [self errorForUnderlyingError:underlyingError];
				}
				[self release];
				self = nil;
				return self;
			}
			ARCategoryTuple *categoryTuple = [[ARCategoryTuple alloc] initWithDictionary:tuple error:&underlyingError];
			if (underlyingError) {
				if (error) {
					*error = [self errorForUnderlyingError:underlyingError];
				}
				[self release];
				self = nil;
				return self;
			}
			[categories addObject:categoryTuple];
			[categoryTuple release];
		}
	}
	return self;
}

- (void)dealloc {
	self.icon = nil;
	[name release];
	[categories release];
	[super dealloc];
}

@end
