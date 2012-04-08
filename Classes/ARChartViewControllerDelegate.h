/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Foundation/Foundation.h>

@class ARChartViewController;

@protocol ARChartViewControllerDelegate <NSObject>

- (void)chartViewController:(ARChartViewController *)controller 
              didUpdateData:(NSArray *)data 
                     sorted:(BOOL)sorted;

@end
