//
//  InFlightBuffers.h
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
#pragma mark - InFlightBuffers
//===------------------------------------------------------------------------===

@interface InFlightBuffers : NSObject

// • Initialization
//
- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                                   size:(NSInteger)bufferSize
                                  count:(NSInteger)bufferCount;
// • Make unavailable
//
- (nonnull instancetype)init NS_UNAVAILABLE;

// • Properties
//
@property (nonnull, nonatomic, readonly) NSArray<id<MTLBuffer>> *buffers;
@property (nonnull, nonatomic, readonly) id<MTLBuffer> currentBuffer;

// • Methods
//
- (nonnull id<MTLBuffer>)nextBuffer;

@end
