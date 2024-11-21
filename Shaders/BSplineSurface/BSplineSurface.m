//
//  BSplineSurface.m
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

#import "BSplineSurface.h"

//===------------------------------------------------------------------------===
#pragma mark - BSplineSurface Implementation
//===------------------------------------------------------------------------===

@implementation BSplineSurface
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

        id<MTLFunction> objectFunction   = [library newFunctionWithName:@"bspline_surface_object"];
        id<MTLFunction> meshFunction     = [library newFunctionWithName:@"bspline_surface_mesh"];
        id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"bspline_surface_fragment"];

        if (nil == objectFunction || nil == meshFunction || nil == fragmentFunction) {
            return nil;
        }

        MTLMeshRenderPipelineDescriptor *pipelineDescriptor = [MTLMeshRenderPipelineDescriptor new];

        pipelineDescriptor.colorAttachments[0].pixelFormat = _pixelFormat;
        pipelineDescriptor.objectFunction                  = objectFunction;
        pipelineDescriptor.meshFunction                    = meshFunction;
        pipelineDescriptor.fragmentFunction                = fragmentFunction;

        NSError *error = nil;

        pipelineState = [library.device newRenderPipelineStateWithMeshDescriptor:pipelineDescriptor
                                                                         options:0
                                                                      reflection:nil
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
               atOffset:(NSInteger)surfaceOffset
                  width:(NSInteger)width
                 height:(NSInteger)height
  colorizedFieldTexture:(nonnull id<MTLTexture>)colorizedFieldTexture {

    [renderEncoder setRenderPipelineState:pipelineState];
    [renderEncoder setObjectBuffer:buffer offset:surfaceOffset atIndex:0];
    [renderEncoder setObjectTexture:colorizedFieldTexture atIndex:0];

    [renderEncoder drawMeshThreadgroups:MTLSizeMake( 1, width, height )
            threadsPerObjectThreadgroup:MTLSizeMake(pipelineState.objectThreadExecutionWidth, 1, 1)
              threadsPerMeshThreadgroup:MTLSizeMake(pipelineState.meshThreadExecutionWidth, 1, 1)];
}

@end
