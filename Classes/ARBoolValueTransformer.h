/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import <Cocoa/Cocoa.h>


typedef BOOL (^EvalBlock)(id value);

@interface ARBoolValueTransformer : NSValueTransformer 

@property (nonatomic, copy) EvalBlock evalBlock;

- (id)initWithEvaluationBlock:(EvalBlock)evaluationBlock;

@end
