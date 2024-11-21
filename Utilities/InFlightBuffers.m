//
//  InFlightBuffers.m
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

#import "InFlightBuffers.h"

//===------------------------------------------------------------------------===
//
#pragma mark - InFlightBuffers Implementation
//
//===------------------------------------------------------------------------===

@implementation InFlightBuffers {

    id<MTLHeap> heap;
    NSInteger   bufferIndex;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                                   size:(NSInteger)bufferSize
                                  count:(NSInteger)bufferCount {

    assert( 2 == bufferCount || 3 == bufferCount );

    self = [super init];

    if (nil != self) {

        // • Create heap
        //
        MTLSizeAndAlign sizeAndAlign = [device heapBufferSizeAndAlignWithLength:bufferSize
                                                                        options:0];

        MTLHeapDescriptor *heapDescriptor = [[MTLHeapDescriptor alloc] init];

        heapDescriptor.cpuCacheMode = MTLCPUCacheModeDefaultCache;
        heapDescriptor.storageMode  = MTLStorageModeShared;
        heapDescriptor.size         = sizeAndAlign.size * bufferCount;

        heap = [device newHeapWithDescriptor:heapDescriptor];

        if (nil == heap) {
            return nil;
        }

        // • Sub-allocate buffers from heap
        //
        NSMutableArray<id<MTLBuffer>> *buffers =
            [[NSMutableArray<id<MTLBuffer>> alloc] initWithCapacity:bufferCount];

        if (nil == buffers) {
            return nil;
        }

        for (NSInteger ib = 0; ib < bufferCount; ++ib) {

            id<MTLBuffer> buffer = [heap newBufferWithLength:sizeAndAlign.size
                                                     options:0];
            if (nil == buffer) {
                return nil;
            }

            [buffers addObject:buffer];
        }

        // • Finalize
        //
        _buffers    = buffers;
        bufferIndex = 0;
    }

    return self;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

// • Properties
//
- (nonnull id<MTLBuffer>)currentBuffer {

    return _buffers[bufferIndex];
}

//===------------------------------------------------------------------------===
#pragma mark - Methods
//===------------------------------------------------------------------------===

- (nonnull id<MTLBuffer>)nextBuffer {

    bufferIndex = (bufferIndex + 1) % _buffers.count;

    return [self currentBuffer];
}

@end
