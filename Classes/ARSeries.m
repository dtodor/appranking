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

#import "ARSeries.h"
#import "ARDataPoint.h"

@implementation ARSeries

@synthesize dataPoints = _dataPoints;
@synthesize color = _color;

- (id)init {
    if (self = [super init]) {
        _dataPoints = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_dataPoints release], _dataPoints = nil;
    [_color release], _color = nil;
    [super dealloc];
}

- (void)addDataPointForX:(CGFloat)x y:(CGFloat)y {
    assert(x >= 0 && x <= 1);
    assert(y >= -1 && y <= 1);
    ARDataPoint *dp = [[ARDataPoint alloc] initWithX:x y:y];
    [(NSMutableArray *)_dataPoints addObject:dp];
    [dp release];
}

- (void)clear {
    [(NSMutableArray *)_dataPoints removeAllObjects];
}

- (void)sort {
    [(NSMutableArray *)_dataPoints sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        ARDataPoint *p1 = (ARDataPoint *)obj1;
        ARDataPoint *p2 = (ARDataPoint *)obj2;
        
        if (p1.x < p2.x) {
            return NSOrderedAscending;
        } else if (p1.x > p2.x) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
}

@end
