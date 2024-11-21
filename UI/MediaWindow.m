//
//  MediaWindow.m
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

#import "MediaWindow.h"

//===------------------------------------------------------------------------===
//
#pragma mark - MediaWindow Implementation
//
//===------------------------------------------------------------------------===

@implementation MediaWindow
{
    // • Data members
    //
    NSTimeInterval lastMouseMove;
    NSTimer*       hideCursorDelayTimer;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nonnull instancetype)initWithContentRect:(NSRect)contentRect
                                  styleMask:(NSWindowStyleMask)style
                                    backing:(NSBackingStoreType)backingStoreType
                                      defer:(BOOL)flag {

    self = [super initWithContentRect:contentRect
                            styleMask:style
                              backing:backingStoreType
                                defer:flag];
    if (nil != self) {

        lastMouseMove = [NSDate timeIntervalSinceReferenceDate];

        // • Set up the timer for hiding the cursor
        //
        [self waitToHideCursor];

        // • Observe close notification
        //
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(windowWillClose:)
                                                   name:NSWindowWillCloseNotification
                                                 object:self];
        // • Finalize
        //
        self.acceptsMouseMovedEvents = YES;
    }

    return self;
}

- (void)dealloc {

    [self stopHidingCursor];
}

//===------------------------------------------------------------------------===
#pragma mark - NSResponder Methods (Mouse)
//===------------------------------------------------------------------------===

- (void)mouseMoved:(NSEvent *)event {

    lastMouseMove = [NSDate timeIntervalSinceReferenceDate];

    [self waitToHideCursor];
}

//===------------------------------------------------------------------------===
#pragma mark - Notifications
//===------------------------------------------------------------------------===

- (void)windowWillClose:(nullable id)sender {

    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:NSWindowWillCloseNotification
                                                object:self];
    [self stopHidingCursor];
}

//===------------------------------------------------------------------------===
#pragma mark - Private Methods
//===------------------------------------------------------------------------===

- (void)waitToHideCursor {

    // TODO: Only hide during media playback
    if (nil != hideCursorDelayTimer) {
        //  - Already waiting to hide
        return;
    }

    // • Set up polling timer that hides the cursor once the mouse has
    //    stopped moving for a certian time
    //
    hideCursorDelayTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           repeats:YES
                                                             block:^(NSTimer * _Nonnull timer) {
        [self tryToHideCursorAfterDelay:2.5];
    }];
}

- (void)tryToHideCursorAfterDelay:(NSTimeInterval)delay {

    if (lastMouseMove + delay <= [NSDate timeIntervalSinceReferenceDate]) {

        [NSCursor setHiddenUntilMouseMoves:YES];

        [hideCursorDelayTimer invalidate];
        hideCursorDelayTimer = nil;
    }
}

- (void)stopHidingCursor {

    // • Stop trying to hide the cursor
    //
    if (nil != hideCursorDelayTimer) {
        [hideCursorDelayTimer invalidate];
        hideCursorDelayTimer = nil;
    }

    [NSCursor setHiddenUntilMouseMoves:NO];
}

@end

