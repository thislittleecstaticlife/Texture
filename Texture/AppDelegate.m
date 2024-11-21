//
//  AppDelegate.m
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

#import "AppDelegate.h"

#import <UI/MediaWindow.h>
#import <UI/PlaybackView.h>

#import <Extensions/NSBundle+Texture.h>

#import <Composition/Renderer.h>

//===------------------------------------------------------------------------===
#pragma mark - AppDelegate Implementation
//===------------------------------------------------------------------------===

@implementation AppDelegate
{
    // • Properties
    //
    NSString            *appName;
    id<MTLDevice>        device;
    id<MTLCommandQueue>  commandQueue;
    Composition         *composition;
    Renderer            *renderer;

    // • Properties (At Launch)
    //
    NSWindow *window;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nonnull instancetype)init {

    self = [super init];

    if (nil != self) {

        if ( ![self failableInit] ) {
            [NSException raise:NSGenericException format:@"Failed to initialize app delegate"];
        }
    }

    return self;
}

- (BOOL)failableInit {

    // • App name
    //
    appName = [NSBundle.mainBundle appName];

    if (nil == appName) {
        return NO;
    }

    // • Metal resources
    //
    device = MTLCreateSystemDefaultDevice();

    if (nil == device) {
        return NO;
    }

    commandQueue = [device newCommandQueue];

    if (nil == commandQueue) {
        return NO;
    }

    id<MTLLibrary> library = [device newDefaultLibrary];

    if (nil == library) {
        return NO;
    }

    // • Composition
    //
    composition = [[Composition alloc] initWithDevice:device];

    if (nil == composition) {
        return NO;
    }

    // • Renderer
    //
    renderer = [[Renderer alloc] initWithComposition:composition
                                             library:library
                                        commandQueue:commandQueue];
    if (nil == renderer) {
        return NO;
    }

    return YES;
}

//===------------------------------------------------------------------------===
#pragma mark - NSApplicationDelegate Methods
//===------------------------------------------------------------------------===

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // • Add a Quit menu item
    //
    NSMenuItem *appMenuItem = [NSApp.mainMenu itemAtIndex:0];

    [appMenuItem.submenu addItemWithTitle:[@"Quit " stringByAppendingString:appName]
                                   action:@selector(terminate:)
                            keyEquivalent:@"q"];

    // • Create the window
    //
    window = [[MediaWindow alloc] initWithContentRect:NSMakeRect(0, 0, 540, 540)
                                            styleMask:(  NSWindowStyleMaskTitled
                                                       | NSWindowStyleMaskClosable
                                                       | NSWindowStyleMaskResizable
                                                       | NSWindowStyleMaskMiniaturizable )
                                              backing:NSBackingStoreBuffered
                                                defer:NO];
    if (nil == window) {
        [NSException raise:NSGenericException format:@"Failed to create window"];
    }

    // • Go ahead and set the title, but hide it
    //
    window.title           = appName;
    window.titleVisibility = NSWindowTitleHidden;

    // • Frame auto-save name
    //
    [window setFrameAutosaveName:[appName stringByAppendingString:@".Window"]];

    // • Content view
    //
    PlaybackView *playbackView = [[PlaybackView alloc] initWithFrame:NSZeroRect
                                                            renderer:self->renderer
                                                        commandQueue:self->commandQueue];

    if (nil == playbackView) {
        [NSException raise:NSGenericException format:@"Failed to create content view"];
    }

    [window setContentView:playbackView];

    CGFloat aspect = (CGFloat)composition.aspectRatio.x / (CGFloat)composition.aspectRatio.y;

    [NSLayoutConstraint activateConstraints:@[
        [playbackView.widthAnchor constraintEqualToAnchor:playbackView.heightAnchor
                                               multiplier:aspect]
    ]];

    [window makeKeyAndOrderFront:nil];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    //  - Nothing
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {

    return NO;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {

    return YES;
}

@end
