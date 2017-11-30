//
//  YLT_DecoderFrame.m
//  Pods
//
//  Created by Alex on 2017/11/26.
//

#import "YLT_DecoderFrame.h"

@implementation YLT_DecoderFrame

@end

@implementation YLT_MovieFrame

@end


@implementation YLT_VideoFrame
- (YLT_MovieFrameType)type { return YLT_MovieFrameTypeVideo; }
@end


@implementation YLT_VideoFrameRGB
- (YLT_VideoFormat)format { return YLT_VideoFormatRGB; }
- (UIImage *)asImage {
    UIImage *image = nil;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(_rgb));
    if (provider) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace) {
            CGImageRef imageRef = CGImageCreate(self.width,
                                                self.height,
                                                8,
                                                24,
                                                self.linesize,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault,
                                                provider,
                                                NULL,
                                                YES, // NO
                                                kCGRenderingIntentDefault);
            if (imageRef) {
                image = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }
            CGColorSpaceRelease(colorSpace);
        }
        CGDataProviderRelease(provider);
    }
    return image;
}
@end


@implementation YLT_VideoFrameYUV
- (YLT_VideoFormat)format { return YLT_VideoFormatYUV; };
@end


@implementation YLT_AudioFrame
- (YLT_MovieFrameType)type { return YLT_MovieFrameTypeAudio; }
@end


@implementation YLT_ArtworkFrame
- (YLT_MovieFrameType)type { return YLT_MovieFrameTypeArtwork; }
- (UIImage *)asImage {
    UIImage *image = nil;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)(_picture));
    if (provider) {
        CGImageRef imageRef = CGImageCreateWithJPEGDataProvider(provider,
                                                                NULL,
                                                                YES,kCGRenderingIntentDefault);
        if (imageRef) {
            image = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
        }
        CGDataProviderRelease(provider);
    }
    return image;
}
@end

@implementation YLT_SubtitleFrame
- (YLT_MovieFrameType)type { return YLT_MovieFrameTypeSubtitle; }
@end

