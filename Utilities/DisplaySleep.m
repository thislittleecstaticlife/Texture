//
//  DisplaySleep.m
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

#import "DisplaySleep.h"
#import <IOKit/pwr_mgt/IOPMLib.h>

//===------------------------------------------------------------------------===
//
#pragma mark - DisplaySleep Implementation
//
//===------------------------------------------------------------------------===

@implementation DisplaySleep
{
    IOPMAssertionID noSleepID;
    BOOL            isSleepDisabled;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithName:(nonnull NSString *)name {

    self = [super init];

    if (nil != self) {

        // • Disable display sleep
        //
        IOReturn result = IOPMAssertionCreateWithName( kIOPMAssertionTypeNoDisplaySleep,
                                                       kIOPMAssertionLevelOn,
                                                       (__bridge CFStringRef)name,
                                                       &noSleepID );

        isSleepDisabled = (kIOReturnSuccess == result);

        if (!isSleepDisabled) {
            return nil;
        }
    }

    return self;
}

- (void)dealloc {

    if (isSleepDisabled) {
        // • Re-enable display sleep
        IOPMAssertionRelease(noSleepID);
        isSleepDisabled = NO;
        noSleepID = 0;
    }
}

@end
