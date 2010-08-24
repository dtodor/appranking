//
//  Configuration.h
//  AppRanking
//
//  Created by Todor Dimitrov on 22.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kConfigurationErrorDomain;

typedef enum {
	CorruptConfigurationFile
} ConfigurationErrorCodes;

@interface ARConfiguration : NSObject {
	NSDictionary *appStoreIds;
	NSDictionary *genres;
	NSDictionary *applications;
}

@property (readonly) NSDictionary *appStoreIds;
@property (readonly) NSDictionary *genres;
@property (readonly) NSDictionary *applications;

+ (ARConfiguration *)sharedARConfiguration;

- (BOOL)loadConfiguration:(NSError **)error;

@end
