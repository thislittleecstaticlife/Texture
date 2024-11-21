//
//  ColorizeField.m
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

#import "ColorizeField.h"

//===------------------------------------------------------------------------===
#pragma mark - ColorizeField Implementation
//===------------------------------------------------------------------------===

@implementation ColorizeField
{
    id<MTLComputePipelineState>  pipelineState;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithLibrary:(nonnull id<MTLLibrary>)library {

    self = [super init];

    if (nil != self) {

        id<MTLFunction> computeFunction = [library newFunctionWithName:@"colorize_field"];

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
                   atOffset:(NSInteger)colorizeFieldOffset
             currentSubstep:(uint8_t)currentSubstep
               fieldTexture:(nonnull id<MTLTexture>)fieldTexture
      colorizedFieldTexture:(nonnull id<MTLTexture>)colorizedFieldTexture {

    [computeEncoder setComputePipelineState:pipelineState];
    [computeEncoder setImageblockWidth:32 height:32];

    [computeEncoder setBuffer:buffer offset:colorizeFieldOffset atIndex:0];
    [computeEncoder setBuffer:buffer offset:0 atIndex:1];

    [computeEncoder setBytes:&currentSubstep length:sizeof(currentSubstep) atIndex:2];

    [computeEncoder setTexture:fieldTexture atIndex:0];
    [computeEncoder setTexture:colorizedFieldTexture atIndex:1];

    [computeEncoder dispatchThreads:MTLSizeMake(colorizedFieldTexture.width,
                                                colorizedFieldTexture.height,
                                                1)
              threadsPerThreadgroup:MTLSizeMake(32, 32, 1)];
}

@end
