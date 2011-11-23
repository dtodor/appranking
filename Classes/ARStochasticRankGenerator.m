/*
 * Copyright (c) 2011 Todor Dimitrov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "ARStochasticRankGenerator.h"


@implementation ARStochasticRankGenerator

#define A 1.0
#define B 1.0
#define C 2.0

double pdf(NSUInteger distance);

double pdf(NSUInteger distance) {
	return 1.0 / (A + B * pow(distance, C));
}

- (id)initWithMinRank:(NSUInteger)min maxRank:(NSUInteger)max {
	if (self = [super init]) {
		assert(max > min);
		minRank = min;
		maxRank = max;
		
		NSUInteger range = maxRank-minRank+1;
		transitionMatrix = malloc(sizeof(double)*range*range);
		for (NSUInteger index = 0; index < range; index++) {
			double sum = 0;
			for (NSUInteger i = 0; i < range; i++) {
				NSUInteger distance = abs(i - index);
				sum += pdf(distance);
			}
			double k = 1.0 / sum;
			for (NSUInteger i = 0; i < range; i++) {
				NSUInteger distance = abs(i - index);
				transitionMatrix[index*range+i] = k * pdf(distance);
			}
		}
		
		currentValue = range/2;
	}
	return self;
}

- (void)dealloc {
	free(transitionMatrix);
	[super dealloc];
}

#define MAX_RANDOM 0x100000000
#define RANDOM ((double)(arc4random()%(MAX_RANDOM+1))/MAX_RANDOM)

- (NSUInteger)nextRankValue {
	NSUInteger range = maxRank-minRank+1;
	NSUInteger offset = currentValue*range;
	double random = RANDOM;
	NSUInteger newValue = 0;
	double sum = 0;
	for (; newValue < range; newValue++) {
		sum += transitionMatrix[offset+newValue];
		if (random <= sum) {
			break;
		}
	}
	currentValue = newValue;
	return currentValue+minRank;
}

@end
