//
//  YLT_VideoDecoder.m
//  FMDB
//
//  Created by Alex on 2017/11/26.
//

#import "YLT_VideoDecoder.h"
#import <YLT_BaseLib/YLT_BaseLib.h>
#import <YLT_FFMpeg/YLT_FFMpeg.h>

@interface YLT_VideoDecoder() {
    struct SwsContext *_swsContext;
    NSUInteger _artworkIndex;
    CGFloat _videoTimeBase;
    CGFloat _fps;
    uint8_t *_out_buffer;
}

@property (nonatomic, weak) YLT_BaseDecoder *baseDecoder;

/**
 视频播放格式
 */
@property (nonatomic, readwrite, assign) YLT_VideoFormat videoFormat;

@end


@implementation YLT_VideoDecoder

/**
 初始化解码器
 
 @param baseCoder 基础
 @return 解码器
 */
+ (YLT_VideoDecoder *)decoderWithBaseDecoder:(YLT_BaseDecoder *)baseCoder {
    YLT_VideoDecoder *result = [[YLT_VideoDecoder alloc] init];
    result.baseDecoder = baseCoder;
    return result;
}

- (BOOL)YLT_OpenVideo {
    if (self.baseDecoder.videoStreams.count == 0) {
        return YES;
    }
    for (NSNumber *num in self.baseDecoder.videoStreams) {
        NSUInteger iStream = num.integerValue;
        if (0 == (self.baseDecoder.formatCtx->streams[iStream]->disposition & AV_DISPOSITION_ATTACHED_PIC)) {
            if ([self YLT_OpenVideoStreamAtIndex:iStream]) {
                return YES;
            }
        } else {//艺术图片流
            _artworkIndex = iStream;
        }
    }
    return NO;
}

- (BOOL)YLT_OpenVideoStreamAtIndex:(NSInteger)iStream {
    AVCodecContext *coderCtx = [self.baseDecoder findCoderForStreamIndex:iStream];
    if (!coderCtx) {
        return NO;
    }
    _videoFrame = av_frame_alloc();
    if (!_videoFrame) {
        avcodec_close(coderCtx);
        avcodec_free_context(&coderCtx);
        [self.baseDecoder YLT_Error:YLT_DecoderErrorAllocateFrame];
        return NO;
    }
    _videoIndex = iStream;
    _videoCodecCtx = coderCtx;
    [self.baseDecoder stream:self.baseDecoder.formatCtx->streams[_videoIndex] defaultTimebase:0.04 fps:&_fps ptimebase:&_videoTimeBase];
    YLT_LogInfo(@"视频打开成功");
    return YES;
}

/**
 设置视频单帧的格式
 
 @param videoFrameFormat 格式
 @return 结果
 */
- (BOOL)setupVideoFrameFormat:(YLT_VideoFormat)videoFrameFormat {
    if (videoFrameFormat == YLT_VideoFormatYUV && _videoCodecCtx && (_videoCodecCtx->pix_fmt==AV_PIX_FMT_YUV420P || _videoCodecCtx->pix_fmt==AV_PIX_FMT_YUVJ420P)) {
        _videoFormat = YLT_VideoFormatYUV;
        return YES;
    }
    _videoFormat = YLT_VideoFormatRGB;
    return _videoFormat == videoFrameFormat;
}


/**
 处理视频帧
 
 @return 视频帧
 */
- (YLT_VideoFrame *)handleVideoFrame {
    if (!self.videoFrame->data[0]) {
        return nil;
    }
    YLT_VideoFrame *frame;
    if (_videoFormat == YLT_VideoFormatYUV) {
        YLT_VideoFrameYUV *yuvFrame = [[YLT_VideoFrameYUV alloc] init];
        yuvFrame.luma = [self copyFrameDataSrc:_videoFrame->data[0] lineSize:_videoFrame->linesize[0] width:_videoCodecCtx->width height:_videoCodecCtx->height];
        yuvFrame.chromaB = [self copyFrameDataSrc:_videoFrame->data[1] lineSize:_videoFrame->linesize[1] width:_videoCodecCtx->width/2. height:_videoCodecCtx->height/2.];
        yuvFrame.chromaR = [self copyFrameDataSrc:_videoFrame->data[2] lineSize:_videoFrame->linesize[2] width:_videoCodecCtx->width/2. height:_videoCodecCtx->height/2.];
        frame = yuvFrame;
    } else {
        if (!_swsContext && ![self setupScaler]) {
            YLT_LogWarn(@"设置Scaler失败");
            return nil;
        }
        av_image_fill_arrays(_pictureFrame->data, _pictureFrame->linesize, _out_buffer, AV_PIX_FMT_RGB24, _videoCodecCtx->width, _videoCodecCtx->height, 1);
        sws_scale(_swsContext,
                  (const uint8_t **)_videoFrame->data,
                  _videoFrame->linesize,
                  0,
                  _videoCodecCtx->height,
                  _pictureFrame->data,
                  _pictureFrame->linesize);
        YLT_VideoFrameRGB *rgbFrame = [[YLT_VideoFrameRGB alloc] init];
        rgbFrame.linesize = _pictureFrame->linesize[0];
        rgbFrame.rgb = [NSData dataWithBytes:_pictureFrame->data[0]
                                      length:rgbFrame.linesize * _videoCodecCtx->height];
        frame = rgbFrame;
    }
    frame.width = _videoCodecCtx->width;
    frame.height = _videoCodecCtx->height;
    
    frame.position = av_frame_get_best_effort_timestamp(_videoFrame)* _videoTimeBase;
    const int64_t frameDuration = av_frame_get_pkt_duration(_videoFrame);
    if (frameDuration) {
        frame.duration = frameDuration * _videoTimeBase;
        frame.duration += _videoFrame->repeat_pict * _videoTimeBase * 0.5;
    }
    else {
        frame.duration = 1.0 / _fps;
    }
    
    return frame;
}

- (void)closeScaler {
    if (_swsContext) {
        sws_freeContext(_swsContext);
        _swsContext = NULL;
    }
    if (_pictureFrame) {
        av_free(&_pictureFrame);
        _pictureFrame = NULL;
    }
    if (_out_buffer) {
        av_free(_out_buffer);
        _out_buffer = NULL;
    }
}

- (BOOL)setupScaler {
    [self closeScaler];
    _pictureFrame = av_frame_alloc();
    
    _out_buffer = (uint8_t *)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_RGB24, _videoCodecCtx->width, _videoCodecCtx->height, 1));
    
    _swsContext = sws_getCachedContext(_swsContext,
                                       _videoCodecCtx->width,
                                       _videoCodecCtx->height,
                                       _videoCodecCtx->pix_fmt,
                                       _videoCodecCtx->width,
                                       _videoCodecCtx->height,
                                       AV_PIX_FMT_RGB24,
                                       SWS_FAST_BILINEAR,
                                       NULL, NULL, NULL);
    
    return _swsContext != NULL;
}

- (BOOL)YLT_CloseVideo {
    _videoIndex = -1;
//    [self clos]
    return NO;
}


#pragma mark - tool method

- (NSData *)copyFrameDataSrc:(UInt8 *)src lineSize:(int)linesize width:(int)width height:(int)height {
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength:width * height];
    Byte *dst = md.mutableBytes;
    for(NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}

#pragma mark - setter getter



@end
