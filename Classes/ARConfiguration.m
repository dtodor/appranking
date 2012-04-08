/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARConfiguration.h"
#import "JSON.h"
#import "SBJSON+Additions.h"
#import "ARCategoryTuple.h"
#import "ARApplication.h"


NSString * const kConfigurationErrorDomain = @"ConfigurationErrorDomain";


@interface ARConfiguration()

@property (nonatomic, strong) NSDictionary *countries;
@property (nonatomic, strong) NSDictionary *genres;

@end

@implementation ARConfiguration

@synthesize countries = _countries;
@synthesize genres = _genres;

+ (ARConfiguration *)sharedARConfiguration
{
    static dispatch_once_t onceToken;
    static ARConfiguration *singleton;
    dispatch_once(&onceToken, ^{
        singleton = [[ARConfiguration alloc] init];
    });
    return singleton;
}

- (NSDictionary *)loadDictionary:(NSString *)fileName error:(NSError **)error 
{
	NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"json"];
	NSString *data = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:error];
	if (data) {
		SBJsonParser *parser = [[SBJsonParser alloc] init];
		NSDictionary *retValue = [parser dictionaryWithString:data error:error];
		return retValue;
	} else {
		return nil;
	}
}

- (NSArray *)loadArray:(NSString *)fileName error:(NSError **)error 
{
	NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"json"];
	NSString *data = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:error];
	if (data) {
		SBJsonParser *parser = [[SBJsonParser alloc] init];
		NSArray *retValue = [parser arrayWithString:data error:error];
		return retValue;
	} else {
		return nil;
	}
}

- (NSError *)errorForUnderlyingError:(NSError *)error 
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:@"Configuration file is corrupt!" forKey:NSLocalizedDescriptionKey];
	if (error) {
		[userInfo setObject:error forKey:NSUnderlyingErrorKey];
	}
	return [NSError errorWithDomain:kConfigurationErrorDomain 
							   code:CorruptConfigurationFile 
						   userInfo:userInfo];
}

- (BOOL)loadConfiguration:(NSError **)error 
{
	@synchronized(self) {
		if (self.countries && self.genres) {
			return YES;
		}
        if (!self.countries) {
            self.countries = [self loadDictionary:@"countries" error:error];
            if (!self.countries) {
                NSLog(@"Unable to load iTunes store ids, error = %@", (error)?[*error localizedDescription]:@"-");
                return NO;
            }
        }
        if (!self.genres) {
            self.genres = [self loadDictionary:@"genres" error:error];
            if (!self.genres) {
                NSLog(@"Unable to load iTunes categories, error = %@", (error)?[*error localizedDescription]:@"-");
                return NO;
            }
        }
		return YES;
	}
}

@end
