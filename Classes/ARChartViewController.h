/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>
#import "ARApplication.h"
#import "ARCategoryTuple.h"
#import "ARChartImageView.h"
#import "ARChartViewControllerDelegate.h"


@interface ARChartViewController : NSViewController

@property (nonatomic) BOOL enabled;
@property (nonatomic, strong) NSArray *allCountries;
@property (nonatomic, strong) ARApplication *application;
@property (nonatomic, strong) ARCategoryTuple *category;

@end
