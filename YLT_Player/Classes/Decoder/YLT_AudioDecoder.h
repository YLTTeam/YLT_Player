//
//  YLT_AudioDecoder.h
//  FMDB
//
//  Created by Alex on 2017/11/26.
//

#import <Foundation/Foundation.h>
#import "YLT_BaseDecoder.h"

@interface YLT_AudioDecoder : NSObject

@property (nonatomic, readwrite, assign) NSInteger audioIndex;

@property (nonatomic) AVCodecContext *audioCodecCtx;
@property (nonatomic) AVFrame *audioFrame;
/**
 初始化解码器
 
 @param baseCoder 基础
 @return 解码器
 */
+ (YLT_AudioDecoder *)decoderWithBaseDecoder:(YLT_BaseDecoder *)baseCoder;

/**
 打开音频流
 
 @return 结果
 */
- (BOOL)YLT_OpenAudio;

/**
 处理音频帧

 @return 音频帧
 */
- (YLT_AudioFrame *)handleAudioFrame;
/**
 关闭流

 @return 结果
 */
- (BOOL)YLT_CloseAuio;

@end
