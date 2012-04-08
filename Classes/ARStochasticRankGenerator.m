/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARStochasticRankGenerator.h"


@implementation ARStochasticRankGenerator {
	double *_transitionMatrix;
	NSUInteger _minRank;
	NSUInteger _maxRank;
	NSUInteger _currentValue;
}

#define A 1.0
#define B 1.0
#define C 2.0

double pdf(NSUInteger distance);

double pdf(NSUInteger distance) 
{
	return 1.0 / (A + B * pow(distance, C));
}

- (id)initWithMinRank:(NSUInteger)min maxRank:(NSUInteger)max 
{
	if (self = [super init]) {
		assert(max > min);
		_minRank = min;
		_maxRank = max;
		
		NSUInteger range = _maxRank-_minRank+1;
		_transitionMatrix = malloc(sizeof(double)*range*range);
		for (NSUInteger index = 0; index < range; index++) {
			double sum = 0;
			for (NSUInteger i = 0; i < range; i++) {
				NSUInteger distance = abs(i - index);
				sum += pdf(distance);
			}
			double k = 1.0 / sum;
			for (NSUInteger i = 0; i < range; i++) {
				NSUInteger distance = abs(i - index);
				_transitionMatrix[index*range+i] = k * pdf(distance);
			}
		}
		
		_currentValue = range/2;
	}
	return self;
}

- (void)dealloc 
{
	free(_transitionMatrix);
}

#define MAX_RANDOM 0x100000000
#define RANDOM ((double)(arc4random()%(MAX_RANDOM+1))/MAX_RANDOM)

- (NSUInteger)nextRankValue 
{
	NSUInteger range = _maxRank-_minRank+1;
	NSUInteger offset = _currentValue*range;
	double random = RANDOM;
	NSUInteger newValue = 0;
	double sum = 0;
	for (; newValue < range; newValue++) {
		sum += _transitionMatrix[offset+newValue];
		if (random <= sum) {
			break;
		}
	}
	_currentValue = newValue;
	return _currentValue+_minRank;
}

@end
