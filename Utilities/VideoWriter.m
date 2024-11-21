//
//  VideoWriter.m
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

#import "VideoWriter.h"

#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

//===------------------------------------------------------------------------===
#pragma mark - VideoWriter Implementation
//===------------------------------------------------------------------------===

@implementation VideoWriter
{
    CMFormatDescriptionRef                videoFormat;
    AVAssetWriterInput                   *videoInput;
    AVAssetWriterInputPixelBufferAdaptor *pixelBufferInput;
    AVAssetWriter                        *assetWriter;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithURL:(NSURL *)outputURL {

    self = [super init];

    if (nil != self) {

        // • Video format
        //
        _outputSize = simd_make_uint2(3840, 2160);

        OSStatus status = CMVideoFormatDescriptionCreate( kCFAllocatorDefault,
                                                          kCVPixelFormatType_64RGBAHalf,
                                                          _outputSize.x,
                                                          _outputSize.y,
                                                          NULL,
                                                          &videoFormat );
        if (noErr != status || NULL == videoFormat) {
            return nil;
        }

        // • Video input
        //
        AVOutputSettingsAssistant *settingsAssistant =
            [AVOutputSettingsAssistant outputSettingsAssistantWithPreset:AVOutputSettingsPresetHEVC3840x2160];

        if (nil == settingsAssistant) {
            return nil;
        }

        settingsAssistant.sourceVideoFormat = videoFormat;

        NSMutableDictionary<NSString *,id> *settings = [settingsAssistant.videoSettings mutableCopy];

        settings[AVVideoColorPropertiesKey] = @{
            AVVideoColorPrimariesKey   : AVVideoColorPrimaries_ITU_R_2020,
            AVVideoTransferFunctionKey : AVVideoTransferFunction_ITU_R_2100_HLG,
            AVVideoYCbCrMatrixKey      : AVVideoYCbCrMatrix_ITU_R_2020
        };

        NSMutableDictionary<NSString *,id> *compressionProperties = settings[AVVideoCompressionPropertiesKey];
        assert( nil != compressionProperties);

        compressionProperties[AVVideoProfileLevelKey] =
            (__bridge NSString *)kVTProfileLevel_HEVC_Main10_AutoLevel;

        compressionProperties[AVVideoAverageBitRateKey]          = @(54*1000*100);
        compressionProperties[AVVideoExpectedSourceFrameRateKey] = @(60);

        videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                    outputSettings:settings
                                                  sourceFormatHint:videoFormat];
        if ( nil == videoInput ) {
            return nil;
        }

        videoInput.expectsMediaDataInRealTime = NO;

        // • Pixel buffer
        //
        NSDictionary *pixelBufferAttributes = @{
            (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_64RGBAHalf),
            (__bridge NSString *)kCVPixelBufferWidthKey  : @(_outputSize.x),
            (__bridge NSString *)kCVPixelBufferHeightKey : @(_outputSize.y)
        };

        pixelBufferInput = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:videoInput
                                                                      sourcePixelBufferAttributes:pixelBufferAttributes];
        if (nil == pixelBufferInput) {
            return nil;
        }

        // • Asset writer
        //
        NSError *error = nil;

        assetWriter = [[AVAssetWriter alloc] initWithURL:outputURL
                                                fileType:AVFileTypeAppleM4V
                                                   error:&error];

        if (nil == assetWriter || nil != error) {
            return nil;
        }

        [assetWriter addInput:videoInput];
    }

    return self;
}

- (void)dealloc {

    if (NULL != videoFormat) {
        CFRelease(videoFormat);
        videoFormat = NULL;
    }
}

//===------------------------------------------------------------------------===
#pragma mark - Methods
//===------------------------------------------------------------------------===

- (BOOL)beginWriting {

    if ( ![assetWriter startWriting] ) {
        return NO;
    }

    [assetWriter startSessionAtSourceTime:kCMTimeZero];

    return YES;
}

- (BOOL)writeFrame:(nonnull id<MTLTexture>)texture index:(NSInteger)frameIndex {

    while ( ![videoInput isReadyForMoreMediaData] ) {
        // Loop
    }

    CVPixelBufferPoolRef pixelBufferPool = [pixelBufferInput pixelBufferPool];

    if ( NULL == pixelBufferPool ) {
        return NO;
    }

    CVPixelBufferRef pixelBuffer = NULL;
    int status = CVPixelBufferPoolCreatePixelBuffer(NULL, pixelBufferPool, &pixelBuffer);

    if ( kCVReturnSuccess != status || NULL == pixelBuffer ) {
        return NO;
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    {
        void     *bufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer);
        size_t    bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        MTLRegion region      = MTLRegionMake2D(0, 0, texture.width, texture.height);

        [texture getBytes:bufferBytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    CVBufferSetAttachment( pixelBuffer, kCVImageBufferColorPrimariesKey,
                           kCVImageBufferColorPrimaries_ITU_R_2020,
                           kCVAttachmentMode_ShouldPropagate );

    CVBufferSetAttachment( pixelBuffer, kCVImageBufferTransferFunctionKey,
                           kCVImageBufferTransferFunction_ITU_R_2020,
                           kCVAttachmentMode_ShouldPropagate );

    CVBufferSetAttachment( pixelBuffer, kCVImageBufferYCbCrMatrixKey,
                           kCVImageBufferYCbCrMatrix_ITU_R_2020,
                           kCVAttachmentMode_ShouldPropagate );

    [pixelBufferInput appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(frameIndex, 60)];

    CVPixelBufferRelease(pixelBuffer);
    pixelBuffer = NULL;

    return YES;
}

- (void)finishWritingWithCompletionHandler:(void (^ _Nonnull)(void))handler {

    [videoInput markAsFinished];

    [assetWriter finishWritingWithCompletionHandler:handler];
}

@end
