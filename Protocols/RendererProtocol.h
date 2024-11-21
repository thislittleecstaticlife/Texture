//
//  RendererProtocol.h
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

#import <Metal/Metal.h>
#import <simd/simd.h>

//===------------------------------------------------------------------------===
//
#pragma mark - RendererProtocol Declaration
//
//===------------------------------------------------------------------------===

@protocol RendererProtocol <NSObject>

@required

// • Properties (Read-Only)
//
@property (nonnull, nonatomic, readonly) CGColorSpaceRef colorspace;
@property (nonnull, nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, readonly) MTLPixelFormat pixelFormat;

// • Methods
//
- (BOOL)prepareFrameOfSize:(simd_uint2)size
         withCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer;

- (void)renderWithEncoder:(nonnull id<MTLRenderCommandEncoder>)renderEncoder;

- (BOOL)nextFrameWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer;

@end
