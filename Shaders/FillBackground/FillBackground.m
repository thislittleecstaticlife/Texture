//
//  FillBackground.m
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

#import "FillBackground.h"

//===------------------------------------------------------------------------===
#pragma mark - FillBackground Implementation
//===------------------------------------------------------------------------===

@implementation FillBackground
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

        id<MTLFunction> vertexFunction   = [library newFunctionWithName:@"fill_background_vertex"];
        id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fill_background_fragment"];

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

- (void)drawWithEncoder:(nonnull id<MTLRenderCommandEncoder>)renderEncoder
             fromBuffer:(nonnull id<MTLBuffer>)buffer
               atOffset:(NSInteger)backgroundColorOffset {

    [renderEncoder setRenderPipelineState:pipelineState];
    [renderEncoder setVertexBuffer:buffer offset:backgroundColorOffset atIndex:0];

    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                      vertexStart:0
                      vertexCount:4];
}

@end
