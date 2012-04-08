/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARBoolValueTransformer.h"


@implementation ARBoolValueTransformer

@synthesize evalBlock;

- (id)initWithEvaluationBlock:(EvalBlock)evaluationBlock 
{
	if (self = [super init]) {
		assert(evaluationBlock);
		self.evalBlock = evaluationBlock;
	}
	return self;
}

+ (Class)transformedValueClass 
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation 
{
    return NO;
}

- (id)transformedValue:(id)value 
{
	return [NSNumber numberWithBool:evalBlock(value)];
}

@end
