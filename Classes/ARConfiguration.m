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

#import "ARConfiguration.h"
#import "JSON.h"
#import "SynthesizeSingleton.h"
#import "SBJSON+Additions.h"
#import "ARCategoryTuple.h"
#import "ARApplication.h"


NSString * const kConfigurationErrorDomain = @"ConfigurationErrorDomain";


@implementation ARConfiguration

SYNTHESIZE_SINGLETON_FOR_CLASS(ARConfiguration)

@synthesize appStoreIds, genres;

- (NSDictionary *)loadDictionary:(NSString *)fileName error:(NSError **)error {
	NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"json"];
	NSString *data = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:error];
	if (data) {
		SBJsonParser *parser = [[SBJsonParser alloc] init];
		NSDictionary *retValue = [parser dictionaryWithString:data error:error];
		[parser release];
		return retValue;
	} else {
		return nil;
	}
}

- (NSArray *)loadArray:(NSString *)fileName error:(NSError **)error {
	NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"json"];
	NSString *data = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:error];
	if (data) {
		SBJsonParser *parser = [[SBJsonParser alloc] init];
		NSArray *retValue = [parser arrayWithString:data error:error];
		[parser release];
		return retValue;
	} else {
		return nil;
	}
}

- (NSError *)errorForUnderlyingError:(NSError *)error {
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:@"Configuration file is corrupt!" forKey:NSLocalizedDescriptionKey];
	if (error) {
		[userInfo setObject:error forKey:NSUnderlyingErrorKey];
	}
	return [NSError errorWithDomain:kConfigurationErrorDomain 
							   code:CorruptConfigurationFile 
						   userInfo:userInfo];
}

- (BOOL)loadConfiguration:(NSError **)error {
	@synchronized(self) {
		if (appStoreIds) {
			return YES;
		}
		appStoreIds = [[self loadDictionary:@"app-store-ids" error:error] retain];
		if (!appStoreIds) {
			NSLog(@"Unable to load iTunes store ids, error = %@", (error)?[*error localizedDescription]:@"-");
			return NO;
		}
		genres = [[self loadDictionary:@"genres" error:error] retain];
		if (!genres) {
			NSLog(@"Unable to load iTunes categories, error = %@", (error)?[*error localizedDescription]:@"-");
			return NO;
		}
		return YES;
	}
}

@end
