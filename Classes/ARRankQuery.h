//
//  Download.h
//  AppRanking
//
//  Created by Todor Dimitrov on 22.08.10.
//  Copyright 2010 Todor Dimitrov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARCategoryTuple.h"

extern NSString * const kErrorDomain;

typedef enum {
	UnableToParseFeed
} RankQueryErrorCodes;

@protocol RankQueryDelegate;

@interface ARRankQuery : NSObject {
	NSURLConnection *connection;
	NSMutableData *receivedData;
	id<RankQueryDelegate> delegate;

	NSString *country;
	ARCategoryTuple *category;
	NSMutableDictionary *ranks;
	BOOL started;
}

@property (readonly, copy) NSString *country;
@property (readonly, copy) ARCategoryTuple *category;
@property (assign) id<RankQueryDelegate> delegate;
@property (readonly) NSDictionary *ranks;

- (id)initWithCountry:(NSString *)aCountry category:(ARCategoryTuple *)aCategory applications:(NSArray *)apps;
- (void)start;

@end

@protocol RankQueryDelegate

- (void)queryDidFinish:(ARRankQuery *)query;
- (void)query:(ARRankQuery *)query didFailWithError:(NSError *)error;

@end

