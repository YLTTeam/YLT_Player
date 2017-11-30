//
//  YLT_DecoderFrame.h
//  Pods
//
//  Created by Alex on 2017/11/26.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, YLT_MovieFrameType) {
    YLT_MovieFrameTypeAudio,
    YLT_MovieFrameTypeVideo,
    YLT_MovieFrameTypeArtwork,
    YLT_MovieFrameTypeSubtitle,
};

typedef NS_ENUM(NSUInteger, YLT_VideoFormat) {
    YLT_VideoFormatRGB,
    YLT_VideoFormatYUV
};

@interface YLT_DecoderFrame : NSObject

@end

@interface YLT_MovieFrame : YLT_DecoderFrame

@property (nonatomic) YLT_MovieFrameType type;
@property (nonatomic) CGFloat position;
@property (nonatomic) CGFloat duration;

@end

@interface YLT_VideoFrame : YLT_MovieFrame
@property (nonatomic) YLT_VideoFormat format;
@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;
@end

@interface YLT_AudioFrame : YLT_MovieFrame
@property (nonatomic, strong) NSData *samples;
@end

@interface YLT_VideoFrameRGB : YLT_VideoFrame
@property (nonatomic) NSUInteger linesize;
@property (nonatomic, strong) NSData *rgb;
- (UIImage *)asImage;
@end

@interface YLT_VideoFrameYUV : YLT_VideoFrame
@property (nonatomic, strong) NSData *luma;
@property (nonatomic, strong) NSData *chromaB;
@property (nonatomic, strong) NSData *chromaR;
@end

@interface YLT_ArtworkFrame : YLT_MovieFrame
@property (nonatomic, strong) NSData *picture;
- (UIImage *) asImage;
@end

@interface YLT_SubtitleFrame : YLT_MovieFrame
@property (nonatomic, strong) NSString *text;
@end
