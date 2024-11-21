//
//  Renderer.m
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

#import "Renderer.h"

#import <Shaders/ClearField/ClearField.h>
#import <Shaders/InitField/InitField.h>
#import <Shaders/ColorizeField/ColorizeField.h>
#import <Shaders/FillBackground/FillBackground.h>
#import <Shaders/BSplineSurface/BSplineSurface.h>
#import <Shaders/StepField/StepField.h>

//===------------------------------------------------------------------------===
//
#pragma mark - Renderer Implementation
//
//===------------------------------------------------------------------------===

@implementation Renderer
{
    id<MTLTexture>  fieldTextures[2];
    ClearField     *clearField;
    InitField      *initField;

    id<MTLTexture>  colorizedFieldTexture;
    ColorizeField  *colorizeField;
    BOOL            shouldColorizeField;

    FillBackground *fillBackground;
    BSplineSurface *bsplineSurface;

    StepField      *stepField;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithComposition:(nonnull Composition *)composition
                                     library:(nonnull id<MTLLibrary>)library
                                commandQueue:(nonnull id<MTLCommandQueue>)commandQueue {
    self = [super init];

    if (nil != self) {

        // • Base properties
        //
        _device           = library.device;
        _composition      = composition;
        _pixelFormat      = MTLPixelFormatRGBA16Float;
        _fieldPixelFormat = MTLPixelFormatRGBA8Uint;

        _colorspace = CGColorSpaceCreateWithName(kCGColorSpaceITUR_2020);

        if (nil == _colorspace) {
            return nil;
        }

        // • Field initialization
        //
        clearField = [[ClearField alloc] initWithLibrary:library
                                             pixelFormat:_fieldPixelFormat];
        if (nil == clearField) {
            return nil;
        }

        initField = [[InitField alloc] initWithLibrary:library
                                           pixelFormat:_fieldPixelFormat];
        if (nil == initField) {
            return nil;
        }

        // • Field colorization
        //
        colorizeField = [[ColorizeField alloc] initWithLibrary:library];

        if (nil == colorizeField) {
            return nil;
        }

        shouldColorizeField = YES;

        // • Surface rendering
        //
        fillBackground = [[FillBackground alloc] initWithLibrary:library
                                                     pixelFormat:_pixelFormat];
        if (nil == fillBackground) {
            return nil;
        }

        bsplineSurface = [[BSplineSurface alloc] initWithLibrary:library
                                                     pixelFormat:_pixelFormat];
        if (nil == bsplineSurface) {
            return nil;
        }

        // • Field stepping
        //
        stepField = [[StepField alloc] initWithLibrary:library];

        if (nil == stepField) {
            return nil;
        }

        // • Textures and resource initialization
        //
        if ( ![self finalInitWithCommandQueue:commandQueue] ) {
            return nil;
        }
    }

    return self;
}

- (nullable instancetype)initFromRenderer:(nonnull Renderer *)sourceRenderer
                              composition:(nonnull Composition *)composition
                             commandQueue:(nonnull id<MTLCommandQueue>)commandQueue {
    self = [super init];

    if (nil != self) {

        // • Copy properties
        //
        _device             = sourceRenderer.device;
        _composition        = composition;
        _pixelFormat        = sourceRenderer.pixelFormat;
        _fieldPixelFormat   = sourceRenderer.fieldPixelFormat;
        _colorspace         = CGColorSpaceRetain(sourceRenderer.colorspace);

        clearField          = sourceRenderer->clearField;
        initField           = sourceRenderer->initField;
        colorizeField       = sourceRenderer->colorizeField;
        shouldColorizeField = YES;
        fillBackground      = sourceRenderer->fillBackground;
        bsplineSurface      = sourceRenderer->bsplineSurface;
        stepField           = sourceRenderer->stepField;

        // • Textures and resource initialization
        //
        if ( ![self finalInitWithCommandQueue:commandQueue] ) {
            return nil;
        }
    }

    return self;
}

- (BOOL)finalInitWithCommandQueue:(nonnull id<MTLCommandQueue>)commandQueue {

    // • Field textures
    //
    MTLTextureDescriptor *fieldDescriptor = [MTLTextureDescriptor new];

    fieldDescriptor.textureType = MTLTextureType2D;
    fieldDescriptor.pixelFormat = _fieldPixelFormat;
    fieldDescriptor.width       = _composition.fieldSize.x;
    fieldDescriptor.height      = _composition.fieldSize.y;

    fieldDescriptor.usage = MTLTextureUsageRenderTarget
                          | MTLTextureUsageShaderRead
                          | MTLTextureUsageShaderWrite;

    for (int ii = 0; ii < 2; ++ii) {

        fieldTextures[ii] = [_device newTextureWithDescriptor:fieldDescriptor];

        if (nil == fieldTextures[ii]) {
            return NO;
        }
    }

    // • Colorized field texture
    //
    MTLTextureDescriptor *colorizedFieldDescriptor = [MTLTextureDescriptor new];

    colorizedFieldDescriptor.textureType = MTLTextureType2D;
    colorizedFieldDescriptor.pixelFormat = _pixelFormat;
    colorizedFieldDescriptor.width       = fieldDescriptor.width;
    colorizedFieldDescriptor.height      = fieldDescriptor.height;

    colorizedFieldDescriptor.usage = MTLTextureUsageShaderRead
                                   | MTLTextureUsageShaderWrite;

    colorizedFieldTexture = [_device newTextureWithDescriptor:colorizedFieldDescriptor];

    if (nil == colorizedFieldTexture) {
        return NO;
    }

    // • Initialize resources
    //
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    BOOL                 success       = (nil != commandBuffer) ? YES : NO;

    // • Initialize first field
    //
    if (success) {

        MTLRenderPassDescriptor *initFieldDescriptor = [MTLRenderPassDescriptor new];

        initFieldDescriptor.colorAttachments[0].texture     = fieldTextures[0];
        initFieldDescriptor.colorAttachments[0].loadAction  = MTLLoadActionDontCare;
        initFieldDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        id<MTLRenderCommandEncoder> initFieldEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:initFieldDescriptor];

        if (nil != initFieldEncoder) {

            [clearField drawWithEncoder:initFieldEncoder];

            [initField drawWithEncoder:initFieldEncoder
                            fromBuffer:_composition.fieldInitBuffer
                              atOffset:_composition.fieldInitOffset
                         instanceCount:_composition.fieldInitInstanceCount];

            [initFieldEncoder endEncoding];

        } else {
            success = NO;
        }
    }

    // • Advance towards visible frames
    //
    if (success && 0 < _composition.initialStepCount) {

        id<MTLComputeCommandEncoder> stepEncoder = [commandBuffer computeCommandEncoder];

        if (nil != stepEncoder) {

            for (NSInteger ii = 0; ii < _composition.initialStepCount; ++ii) {

                [self stepWithEncoder:stepEncoder];
            }

            [stepEncoder endEncoding];

        } else {
            success = NO;
        }
    }

    if (nil != commandBuffer) {
        [commandBuffer commit];
    }

    return success;
}

- (void)dealloc {

    if (NULL != _colorspace) {
        CGColorSpaceRelease(_colorspace);
        _colorspace = NULL;
    }
}

//===------------------------------------------------------------------------===
#pragma mark - Methods
//===------------------------------------------------------------------------===

- (BOOL)prepareFrameOfSize:(simd_uint2)size
         withCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer {

    if (!shouldColorizeField) {
        return YES;
    }

    id<MTLComputeCommandEncoder> colorizeFieldEncoder = [commandBuffer computeCommandEncoder];

    if (nil == colorizeFieldEncoder) {
        return NO;
    }

    [colorizeField dispatchWithEncoder:colorizeFieldEncoder
                            fromBuffer:_composition.colorizeFieldBuffer
                              atOffset:_composition.colorizeFieldOffset
                        currentSubstep:_composition.currentSubstep
                          fieldTexture:fieldTextures[0]
                 colorizedFieldTexture:colorizedFieldTexture];

    [colorizeFieldEncoder endEncoding];
    shouldColorizeField = NO;

    return YES;
}

- (void)renderWithEncoder:(nonnull id<MTLRenderCommandEncoder>)renderEncoder {

    [fillBackground drawWithEncoder:renderEncoder
                         fromBuffer:_composition.backgroundColorBuffer
                           atOffset:_composition.backgroundColorOffset];

    [bsplineSurface drawWithEncoder:renderEncoder
                         fromBuffer:_composition.surfaceBuffer
                           atOffset:_composition.surfaceOffset
                              width:_composition.surfaceDimensions.x
                             height:_composition.surfaceDimensions.y
              colorizedFieldTexture:colorizedFieldTexture];
}

- (BOOL)nextFrameWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer {

    if (_composition.shouldStepNext) {

        id<MTLComputeCommandEncoder> stepEncoder = [commandBuffer computeCommandEncoder];

        if (nil == stepEncoder) {
            return NO;
        }

        [self stepWithEncoder:stepEncoder];
        [stepEncoder endEncoding];
    }

    [_composition nextSubstep];
    shouldColorizeField = YES;

    return YES;
}

//===------------------------------------------------------------------------===
#pragma mark - Private Methods
//===------------------------------------------------------------------------===

- (void)stepWithEncoder:(nonnull id<MTLComputeCommandEncoder>)stepEncoder {

    [stepField dispatchWithEncoder:stepEncoder
                        fromBuffer:_composition.ruleBuffer
                          atOffset:_composition.ruleOffset
                sourceFieldTexture:fieldTextures[0]
           destinationFieldTexture:fieldTextures[1]];

    id<MTLTexture> temp = fieldTextures[0];
    fieldTextures[0] = fieldTextures[1];
    fieldTextures[1] = temp;
}

@end
