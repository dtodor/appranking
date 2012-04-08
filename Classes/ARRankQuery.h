/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Foundation/Foundation.h>
#import "ARCategoryTuple.h"

extern NSString * const kErrorDomain;

typedef enum {
	UnableToParseFeed
} RankQueryErrorCodes;

@protocol ARRankQueryDelegate;

@interface ARRankQuery : NSObject {

}

@property (nonatomic, readonly, copy) NSString *country;
@property (nonatomic, readonly, strong) ARCategoryTuple *category;
@property (nonatomic, assign) id<ARRankQueryDelegate> delegate;
@property (nonatomic, readonly, strong) NSDictionary *ranks;
@property (nonatomic, readonly, strong) NSDictionary *icons;
@property (nonatomic, readonly, getter=isCached) BOOL cached;
@property (nonatomic, readonly, strong) NSDate *expiryDate;

- (id)initWithCountry:(NSString *)aCountry category:(ARCategoryTuple *)aCategory;
- (void)start;
- (void)cancel;

@end

@protocol ARRankQueryDelegate

- (void)queryDidFinish:(ARRankQuery *)query;
- (void)query:(ARRankQuery *)query didFailWithError:(NSError *)error;

@end

