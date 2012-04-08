/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Foundation/Foundation.h>

extern NSString * const kConfigurationErrorDomain;

typedef enum {
	CorruptConfigurationFile
} ConfigurationErrorCodes;


@interface ARConfiguration : NSObject

// NSString -> NSString
@property (nonatomic, readonly, strong) NSDictionary *countries;

// NSString -> NSString
@property (nonatomic, readonly, strong) NSDictionary *genres;

+ (ARConfiguration *)sharedARConfiguration;

- (BOOL)loadConfiguration:(NSError **)error;

@end
