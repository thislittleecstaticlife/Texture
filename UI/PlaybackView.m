//
//  PlaybackView.m
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

#import "PlaybackView.h"

#import <Utilities/DisplaySleep.h>

//===------------------------------------------------------------------------===
//
#pragma mark - PlaybackView Implementation
//
//===------------------------------------------------------------------------===

@implementation PlaybackView
{
    // • Non-null
    //
    id<RendererProtocol> renderer;
    id<MTLCommandQueue>  commandQueue;
    dispatch_semaphore_t semaphore;

    // • Nullable when not playing
    //
    CAMetalDisplayLink *displayLink;
    DisplaySleep       *displaySleep;

    BOOL shouldStep;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithFrame:(NSRect)frameRect
                              renderer:(nonnull id<RendererProtocol>)renderer
                          commandQueue:(nonnull id<MTLCommandQueue>)commandQueue {
    self = [super init];

    if (nil != self) {

        self->renderer     = renderer;
        self->commandQueue = commandQueue;

        semaphore = dispatch_semaphore_create(PlaybackView.maximumDrawableCount);

        if (NULL == semaphore) {
            return nil;
        }

        shouldStep = NO;

        _shouldBeginPaused = NO;

        // • Configure layer
        //
        self.metalLayer.device               = renderer.device;
        self.metalLayer.colorspace           = renderer.colorspace;
        self.metalLayer.pixelFormat          = renderer.pixelFormat;
        self.metalLayer.maximumDrawableCount = [PlaybackView maximumDrawableCount];
        self.metalLayer.framebufferOnly      = YES;
        self.metalLayer.delegate             = self;
    }

    return self;
}

//===------------------------------------------------------------------------===
#pragma mark - Class Properties (Read-Only)
//===------------------------------------------------------------------------===

+ (NSInteger)maximumDrawableCount {

    return 3;
}

//===------------------------------------------------------------------------===
#pragma mark - Properties (Read-Only)
//===------------------------------------------------------------------------===

- (BOOL)isPaused {

    return (nil == displayLink) ? YES : NO;
}

//===------------------------------------------------------------------------===
#pragma mark - NSView Methods (Key Handling)
//===------------------------------------------------------------------------===

- (BOOL)acceptsFirstResponder {

    return YES;
}

- (void)keyDown:(nonnull NSEvent *)event {

    // • Key code values for Apple Extended Keyboard II
    //    from Inside Macintosh: Text, Appendix C
    //
    if (49 == event.keyCode) {

        // • Play or pause on space bar
        //
        if (self.isPaused) {

            [self beginDisplayLink];

        } else {

            [self endDisplayLink];
        }

    } else if (124 == event.keyCode) {

        // • Step on right arrow if paused - don't yet if ever worry
        //      about accumulating multiple step requests if received
        //      before the next call to displayLayer:
        //
        if (self.isPaused) {

            if (shouldStep) {
                NSLog(@"Multiple step requests before display:");
            }

            shouldStep = YES;
            [self.metalLayer setNeedsDisplay];
        }
    }
}

//===------------------------------------------------------------------------===
#pragma mark - Notifications
//===------------------------------------------------------------------------===

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];

    if (self.isPaused && !_shouldBeginPaused) {

        [self beginDisplayLink];
    }
}

- (void)viewWillMoveToWindow:(nullable NSWindow *)newWindow {
    [super viewWillMoveToWindow:newWindow];

    if (!self.isPaused && newWindow != self.window) {

        _shouldBeginPaused = NO;
        [self endDisplayLink];
    }
}

- (void)windowWillClose:(nullable id)sender {
    [super windowWillClose:sender];

    [self endDisplayLink];
}

- (void)disResizeDrawable:(CGSize)newSize {

    if (self.isPaused) {

        [self.metalLayer setNeedsDisplay];
    }
}

//===------------------------------------------------------------------------===
#pragma mark - Private Methods (Display Link)
//===------------------------------------------------------------------------===

- (void)beginDisplayLink {

    assert( nil == displayLink );

    if (nil == self.window) {
        return;
    }

    displayLink = [[CAMetalDisplayLink alloc] initWithMetalLayer:self.metalLayer];

    if (nil == displayLink) {
        return;
    }

    displayLink.preferredFrameRateRange = CAFrameRateRangeMake(60.0f, 60.0f, 60.0f);
    displayLink.preferredFrameLatency   = 1.0f;
    displayLink.paused                  = NO;
    displayLink.delegate                = self;

    [displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSDefaultRunLoopMode];

    // • It's not catastrophic if this for some reason fails
    //
    displaySleep = [[DisplaySleep alloc] initWithName:@"Disable display sleep for display link"];

    // TODO: Notify MediaWindow that playback is in progress
}

- (void)endDisplayLink {

    if (nil == displayLink) {
        return;
    }

    displayLink.paused = YES;
    [displayLink invalidate];

    displayLink  = nil;
    displaySleep = nil;

    // TODO: Notify MediaWindow that playback is has paused
}

//===------------------------------------------------------------------------===
#pragma mark - Private Methods (Display)
//===------------------------------------------------------------------------===

- (nullable id<MTLCommandBuffer>)beginRendering {

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

    if (nil == commandBuffer) {
        dispatch_semaphore_signal(semaphore);
        return nil;
    }

    __block dispatch_semaphore_t blockSemaphore = semaphore;

    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull _) {

        dispatch_semaphore_signal(blockSemaphore);
    }];

    return commandBuffer;
}

//===------------------------------------------------------------------------===
#pragma mark - CALayerDelegate Methods
//===------------------------------------------------------------------------===

- (void)displayLayer:(CALayer *)layer {

    if (!self.isPaused) {
        return;
    }

    id<MTLCommandBuffer> commandBuffer = [self beginRendering];

    if (nil == commandBuffer) {
        return;
    }

    BOOL success = YES;

    if (shouldStep) {

        if ([renderer nextFrameWithCommandBuffer:commandBuffer]) {
            shouldStep = NO;
        } else {
            success = YES;
        }
    }

    if (success) {

        success = [renderer prepareFrameOfSize:self.frameSize withCommandBuffer:commandBuffer];
    }

    if (success) {

        id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];

        if (nil != drawable) {

            MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];

            renderPassDescriptor.colorAttachments[0].texture     = drawable.texture;
            renderPassDescriptor.colorAttachments[0].loadAction  = MTLLoadActionDontCare;
            renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

            id<MTLRenderCommandEncoder> renderEncoder =
                [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

            if (nil != renderEncoder) {

                [renderer renderWithEncoder:renderEncoder];

                [renderEncoder endEncoding];

            } else {
                success = NO;
            }

            [commandBuffer presentDrawable:drawable];
        }
    }

    [commandBuffer commit];
}

//===------------------------------------------------------------------------===
#pragma mark - CAMetalDisplayLinkDelegate Methods
//===------------------------------------------------------------------------===

- (void)metalDisplayLink:(CAMetalDisplayLink *)link
             needsUpdate:(CAMetalDisplayLinkUpdate *)update {

    id<MTLCommandBuffer> commandBuffer = [self beginRendering];

    if (nil == commandBuffer) {
        return;
    }

    if ( [renderer prepareFrameOfSize:self.frameSize withCommandBuffer:commandBuffer] ) {

        MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];

        renderPassDescriptor.colorAttachments[0].texture     = update.drawable.texture;
        renderPassDescriptor.colorAttachments[0].loadAction  = MTLLoadActionDontCare;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

        if (nil != renderEncoder) {

            [renderer renderWithEncoder:renderEncoder];
            [renderEncoder endEncoding];

            [renderer nextFrameWithCommandBuffer:commandBuffer];
        }
    }

    [commandBuffer presentDrawable:update.drawable];
    [commandBuffer commit];
}

@end
