//
//  VideoWriter.h
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
#pragma mark - VideoWriter
//===------------------------------------------------------------------------===

@interface VideoWriter : NSObject

// • Initialization
//
- (nullable instancetype)initWithURL:(nonnull NSURL *)outputURL;

// • Make unavailable
//
- (nonnull instancetype)init NS_UNAVAILABLE;

// • Properties
//
@property (nonatomic, readonly) simd_uint2 outputSize;

// • Methods
//
- (BOOL)beginWriting;
- (BOOL)writeFrame:(nonnull id<MTLTexture>)texture index:(NSInteger)frameIndex;
- (void)finishWritingWithCompletionHandler:(void (^ _Nonnull)(void))handler;


@end