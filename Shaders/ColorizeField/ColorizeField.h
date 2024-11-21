//
//  ColorizeField.h
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

//===------------------------------------------------------------------------===
#pragma mark - ColorizeField Declaration
//===------------------------------------------------------------------------===

@interface ColorizeField : NSObject

// • Initialization
//
- (nullable instancetype)initWithLibrary:(nonnull id<MTLLibrary>)library;

// • Make unavailable
//
- (nonnull instancetype)init NS_UNAVAILABLE;

// • Methods
//
- (void)dispatchWithEncoder:(nonnull id<MTLComputeCommandEncoder>)computeEncoder
                 fromBuffer:(nonnull id<MTLBuffer>)buffer
                   atOffset:(NSInteger)colorizeFieldOffset
             currentSubstep:(uint8_t)currentSubstep
               fieldTexture:(nonnull id<MTLTexture>)fieldTexture
      colorizedFieldTexture:(nonnull id<MTLTexture>)colorizedFieldTexture;

@end
