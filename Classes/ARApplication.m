/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARApplication.h"


@implementation ARApplication

@dynamic appStoreId;
@dynamic name;
@dynamic categories;
@dynamic iconData;
@dynamic rankEntries;
@synthesize iconImage = _iconImage;

- (void)awakeFromFetch 
{
	if (self.iconData) {
		self.iconImage = [[NSImage alloc] initWithData:self.iconData];
	}
}

- (NSImage *)iconImage 
{
	return _iconImage;
}

- (void)setIconImage:(NSImage *)image 
{
	if (_iconImage != image) {
		[self willChangeValueForKey:@"iconImage"];
		_iconImage = image;
		if (_iconImage) {
			self.iconData = [NSBitmapImageRep representationOfImageRepsInArray:[_iconImage representations] 
																	 usingType:NSJPEGFileType
																	properties:nil];
		} else {
			self.iconData = nil;
		}
		[self didChangeValueForKey:@"iconImage"];
	}
}

- (BOOL)validateCategories:(id *)value error:(NSError **)error 
{
	if (*value == nil) {
		return YES;
	}
	if ([*value count] == 0) {
		if (error) {
			*error = [NSError errorWithDomain:@"ARApplication" 
										 code:0 
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"At least one category should be specified"] 
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return NO;
	} else {
		return YES;
	}
}

@end
