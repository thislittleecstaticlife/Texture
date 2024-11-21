//
//  PlaybackView.h
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

#import "MetalLayerView.h"

#import <Protocols/RendererProtocol.h>

//===------------------------------------------------------------------------===
//
#pragma mark - PlaybackView Declaration
//
//===------------------------------------------------------------------------===

@interface PlaybackView : MetalLayerView <CALayerDelegate, CAMetalDisplayLinkDelegate>

// • Initialization
//
- (nullable instancetype)initWithFrame:(NSRect)frameRect
                              renderer:(nonnull id<RendererProtocol>)renderer
                          commandQueue:(nonnull id<MTLCommandQueue>)commandQueue;

// • Make unavailable
//
- (nonnull instancetype)initWithFrame:(NSRect)frameRect NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder NS_UNAVAILABLE;

// • Class Properties (Read-Only)
//
@property (class, nonatomic, readonly) NSInteger maximumDrawableCount;

// • Properties
//
@property (nonatomic, readwrite) BOOL shouldBeginPaused;
@property (nonatomic, readonly) BOOL paused;

@end
