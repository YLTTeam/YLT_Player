//
//  YLT_VideoDecoder.h
//  FMDB
//
//  Created by Alex on 2017/11/26.
//

#import <Foundation/Foundation.h>
#import "YLT_BaseDecoder.h"

@interface YLT_VideoDecoder : NSObject
/**
 视频的索引号
 */
@property (nonatomic, readwrite, assign) NSInteger videoIndex;

@property (nonatomic, readwrite) AVFrame *videoFrame;
@property (nonatomic, readwrite) AVFrame *pictureFrame;

@property (nonatomic) AVCodecContext *videoCodecCtx;

/**
 初始化解码器
 
 @param baseCoder 基础
 @return 解码器
 */
+ (YLT_VideoDecoder *)decoderWithBaseDecoder:(YLT_BaseDecoder *)baseCoder;

/**
 打开视频流

 @return 结果
 */
- (BOOL)YLT_OpenVideo;

/**
 设置视频单帧的格式

 @param videoFrameFormat 格式
 @return 结果
 */
- (BOOL)setupVideoFrameFormat:(YLT_VideoFormat)videoFrameFormat;

/**
 处理视频帧

 @return 视频帧
 */
- (YLT_VideoFrame *)handleVideoFrame;
/**
 关闭视频流

 @return 结果
 */
- (BOOL)YLT_CloseVideo;

@end
