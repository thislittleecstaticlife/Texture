//
//  Renderer.h
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
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

#import <Protocols/RendererProtocol.h>
#import <Composition/Composition.h>

//===------------------------------------------------------------------------===
//
#pragma mark - Renderer Declaration
//
//===------------------------------------------------------------------------===

@interface Renderer : NSObject <RendererProtocol>

// • Initialization
//
- (nullable instancetype)initWithComposition:(nonnull Composition *)composition
                                     library:(nonnull id<MTLLibrary>)library
                                commandQueue:(nonnull id<MTLCommandQueue>)commandQueue;

- (nullable instancetype)initFromRenderer:(nonnull Renderer *)sourceRenderer
                              composition:(nonnull Composition *)composition
                             commandQueue:(nonnull id<MTLCommandQueue>)commandQueue;

// • Properties (RendererProtocol, Read-Only)
//
@property (nonnull, nonatomic, readonly) CGColorSpaceRef colorspace;
@property (nonnull, nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, readonly) MTLPixelFormat pixelFormat;

// • Properties (Read-Only)
//
@property (nonnull, nonatomic, readonly) Composition *composition;
@property (nonatomic, readonly) MTLPixelFormat fieldPixelFormat;

// • Methods (RendererProtocol)
//
- (BOOL)prepareFrameOfSize:(simd_uint2)size
         withCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer;

- (void)renderWithEncoder:(nonnull id<MTLRenderCommandEncoder>)renderEncoder;

- (BOOL)nextFrameWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer;

@end
