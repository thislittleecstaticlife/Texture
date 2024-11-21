//
//  MetalLayerView.m
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

//===------------------------------------------------------------------------===
//
#pragma mark - MetalLayerView Implementation
//
//===------------------------------------------------------------------------===

@implementation MetalLayerView

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nonnull instancetype)initWithFrame:(NSRect)frameRect {

    self = [super initWithFrame:frameRect];

    if (nil != self) {

        [self commonInit];
    }

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {

    self = [super initWithCoder:coder];

    if (nil != self) {

        [self commonInit];
    }

    return self;
}

- (void)commonInit {

    // • Metal layer
    //
    _metalLayer = [[CAMetalLayer alloc] init];

    if (nil == _metalLayer) {
        //  - don't try to recover
        [NSException raise:NSGenericException format:@"Failed to create Metal Layer"];
    }

    // • Layer-backed view
    //
    self.wantsLayer                = YES;
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;
}

//===------------------------------------------------------------------------===
#pragma mark - Properties (Read-Only)
//===------------------------------------------------------------------------===

- (simd_uint2)frameSize {

    return simd_make_uint2( (uint32_t)_metalLayer.drawableSize.width,
                            (uint32_t)_metalLayer.drawableSize.height );
}

//===------------------------------------------------------------------------===
#pragma mark - NSView Methods
//===------------------------------------------------------------------------===

- (CALayer *)makeBackingLayer {

    return _metalLayer;
}

- (void)viewDidChangeBackingProperties {
    [super viewDidChangeBackingProperties];
    [self resizeDrawable];
}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    [self resizeDrawable];
}

- (void)setBoundsSize:(NSSize)newSize {
    [super setBoundsSize:newSize];
    [self resizeDrawable];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {

    if (nil == self.window || newWindow == self.window) {
        return;
    }

    // • Stop observing notifications
    //
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    // • Full screen notifications
    //
    [notificationCenter removeObserver:self
                                  name:NSWindowWillExitFullScreenNotification
                                object:self.window];

    [notificationCenter removeObserver:self
                                  name:NSWindowDidEnterFullScreenNotification
                                object:self.window];

    // • Window will close notification
    //
    [notificationCenter removeObserver:self
                                  name:NSWindowWillCloseNotification
                                object:self.window];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];

    if (nil == self.window) {
        return;
    }

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    // • Full screen notifications
    //
    [notificationCenter addObserver:self
                           selector:@selector(didEnterFullScreen:)
                               name:NSWindowDidEnterFullScreenNotification
                             object:self.window];

    [notificationCenter addObserver:self
                           selector:@selector(willExitFullScreen:)
                               name:NSWindowWillExitFullScreenNotification
                             object:self.window];

    // • Window close notification
    //
    [notificationCenter addObserver:self
                           selector:@selector(windowWillClose:)
                               name:NSWindowWillCloseNotification
                             object:self.window];
}

//===------------------------------------------------------------------------===
#pragma mark - Resizing
//===------------------------------------------------------------------------===

- (void)resizeDrawable {

    CGFloat scale   = self.window.backingScaleFactor;
    CGSize  newSize = CGSizeMake(self.bounds.size.width * scale, self.bounds.size.height * scale);

    if ( newSize.width <= 0.0 || newSize.height <= 0.0
        || CGSizeEqualToSize(newSize, _metalLayer.drawableSize) )
    {
        return;
    }

    _metalLayer.drawableSize = newSize;
    [_metalLayer setNeedsDisplay];

    [self didResizeDrawable:newSize];
}

- (void)didResizeDrawable:(CGSize)newSize {

    // • Nothing in base implementation
}

- (void)didEnterFullScreen:(nullable id)sender {

    // • Nothing in base implementation
}

- (void)willExitFullScreen:(nullable id)sender {

    // • Nothing in base implementation
}

- (void)windowWillClose:(nullable id)sender {

    // • Nothing in base implementation
}

//===------------------------------------------------------------------------===
#pragma mark - CALayerDelegate Methods
//===------------------------------------------------------------------------===

- (void)displayLayer:(CALayer *)layer {

    [NSException raise:NSGenericException
                format:@"Subclasses of MetalLayerView must implement -displayLayer:"];
}

@end
