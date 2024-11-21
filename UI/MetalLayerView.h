//
//  MetalLayerView.h
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

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

//===------------------------------------------------------------------------===
#pragma mark - MetalLayerView Declaration
//===------------------------------------------------------------------------===

@interface MetalLayerView : NSView

// • Properties (Read-Only)
//
@property (nonnull, nonatomic, readonly) CAMetalLayer *metalLayer;
@property (nonatomic, readonly) simd_uint2 frameSize; // Same as metalLayer.drawableSize

// • Resizing (Nothing in base implementation)
//
- (void)didResizeDrawable:(CGSize)newSize;

// • Notifications (Nothing in base implementation)
//
- (void)didEnterFullScreen:(nullable id)sender;
- (void)willExitFullScreen:(nullable id)sender;
- (void)windowWillClose:(nullable id)sender;

@end
