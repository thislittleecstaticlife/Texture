//
//  ClearField.m
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

#import "ClearField.h"

//===------------------------------------------------------------------------===
#pragma mark - ClearField Implementation
//===------------------------------------------------------------------------===

@implementation ClearField
{
    id<MTLRenderPipelineState>  pipelineState;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithLibrary:(nonnull id<MTLLibrary>)library
                             pixelFormat:(MTLPixelFormat)pixelFormat {

    self = [super init];

    if (nil != self) {

        _pixelFormat = pixelFormat;

        id<MTLFunction> vertexFunction   = [library newFunctionWithName:@"clear_field_vertex"];
        id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"clear_field_fragment"];

        if (nil == vertexFunction || nil == fragmentFunction) {
            return nil;
        }

        MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];

        pipelineDescriptor.colorAttachments[0].pixelFormat = _pixelFormat;
        pipelineDescriptor.vertexFunction                  = vertexFunction;
        pipelineDescriptor.fragmentFunction                = fragmentFunction;

        NSError *error = nil;

        pipelineState = [library.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
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

- (void)drawWithEncoder:(nonnull id<MTLRenderCommandEncoder>)renderEncoder {

    [renderEncoder setRenderPipelineState:pipelineState];

    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                      vertexStart:0
                      vertexCount:4];
}

@end