//
//  StepField.m
//
//  Copyright © 2024 Robert Guequierre
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

#import "StepField.h"

//===------------------------------------------------------------------------===
#pragma mark - StepField Implementation
//===------------------------------------------------------------------------===

@implementation StepField
{
    id<MTLComputePipelineState>  pipelineState;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithLibrary:(nonnull id<MTLLibrary>)library {

    self = [super init];

    if (nil != self) {

        id<MTLFunction> computeFunction = [library newFunctionWithName:@"step_field"];

        if (nil == computeFunction) {
            return nil;
        }

        NSError *error = nil;

        pipelineState = [library.device newComputePipelineStateWithFunction:computeFunction
                                                                      error:&error];
        if (nil == pipelineState || nil != error) {
            return nil;
        }
    }

    return self;
}

//===------------------------------------------------------------------------===
#pragma mark - Methods
//===------------------------------------------------------------------------===

- (void)dispatchWithEncoder:(nonnull id<MTLComputeCommandEncoder>)computeEncoder
                 fromBuffer:(nonnull id<MTLBuffer>)buffer
                   atOffset:(NSInteger)stepFieldOffset
         sourceFieldTexture:(nonnull id<MTLTexture>)sourceFieldTexture
    destinationFieldTexture:(nonnull id<MTLTexture>)destFieldTexture {

    [computeEncoder setComputePipelineState:pipelineState];
    [computeEncoder setImageblockWidth:32 height:32];
    [computeEncoder setBuffer:buffer offset:stepFieldOffset atIndex:0];

    [computeEncoder setTexture:sourceFieldTexture atIndex:0];
    [computeEncoder setTexture:destFieldTexture atIndex:1];

    [computeEncoder setThreadgroupMemoryLength:34 * 34 * 4 atIndex:0];

    [computeEncoder dispatchThreads:MTLSizeMake(destFieldTexture.width,
                                                destFieldTexture.height,
                                                1)
              threadsPerThreadgroup:MTLSizeMake(32, 32, 1)];
}

@end
