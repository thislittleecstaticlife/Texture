//
//  Composition.h
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

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

//===------------------------------------------------------------------------===
//
#pragma mark - Composition Declaration
//
//===------------------------------------------------------------------------===

@interface Composition : NSObject

// • Initialization
//
- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device;

// • Properties (Field Initialization)
//
@property (nonnull, nonatomic, readonly) id<MTLBuffer> fieldInitBuffer;
@property (nonatomic, readonly) NSInteger fieldInitOffset;
@property (nonatomic, readonly) NSInteger fieldInitInstanceCount;
@property (nonatomic, readonly) simd_uint2 fieldSize;
@property (nonatomic, readonly) NSInteger initialStepCount;

// • Properties (Rule)
//
@property (nonnull, nonatomic, readonly) id<MTLBuffer> ruleBuffer;
@property (nonatomic, readonly) NSInteger ruleOffset;

// • Properties (Colorization)
//
@property (nonnull, nonatomic, readonly) id<MTLBuffer> colorizeFieldBuffer;
@property (nonatomic, readonly) NSInteger colorizeFieldOffset;

// • Properties (Surface)
//
@property (nonnull, nonatomic, readonly) id<MTLBuffer> backgroundColorBuffer;
@property (nonatomic, readonly) NSInteger backgroundColorOffset;

@property (nonnull, nonatomic, readonly) id<MTLBuffer> surfaceBuffer;
@property (nonatomic, readonly) NSInteger surfaceOffset;
@property (nonatomic, readonly) simd_uint2 surfaceDimensions;

// • Properties (Output)
//
@property (nonatomic, readonly) simd_uint2 aspectRatio;

// • Properties (State)
//
@property (nonatomic, readonly) BOOL shouldStepNext;
@property (nonatomic, readonly) uint8_t currentSubstep;

// • Methods (State)
//
- (void)nextSubstep;

@end
