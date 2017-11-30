//
//  YLT_DecoderManager.h
//  FMDB
//
//  Created by Alex on 2017/11/26.
//

#import <Foundation/Foundation.h>
#import <YLT_FFMpeg/YLT_FFMpeg.h>
#import "YLT_VideoDecoder.h"
#import "YLT_AudioDecoder.h"
#import "YLT_SubtitleDecoder.h"
#import "YLT_BaseDecoder.h"
#import "YLT_DecoderFrame.h"

@interface YLT_DecoderManager : NSObject

/**
 视频的流索引
 */
@property (nonatomic, readwrite, assign) NSInteger videoStreamIndex;
/**
 音频流索引
 */
@property (nonatomic, readwrite, assign) NSInteger audioStreamIndex;
/**
 字幕流索引
 */
@property (nonatomic, readwrite, assign) NSInteger subtitleStreamIndex;
/**
 艺术照流索引
 */
@property (nonatomic, readwrite, assign) NSInteger artworkStreamIndex;


/**
 基础库
 */
@property (nonatomic, strong) YLT_BaseDecoder *baseDecoder;
@property (nonatomic, strong) YLT_VideoDecoder *videoDecoder;
@property (nonatomic, strong) YLT_AudioDecoder *audioDecoder;
@property (nonatomic, strong) YLT_SubtitleDecoder *subtitleDecoder;

/**
 解码器打开文件
 
 @param filePath 文件路径
 */
- (void)YLT_OpenFile:(NSString *)filePath;

@end
