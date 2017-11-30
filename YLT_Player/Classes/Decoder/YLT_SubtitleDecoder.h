//
//  YLT_SubtitleDecoder.h
//  FMDB
//
//  Created by Alex on 2017/11/26.
//

#import <Foundation/Foundation.h>
#import "YLT_BaseDecoder.h"

@interface YLT_SubtitleDecoder : NSObject

@property (nonatomic, assign) NSInteger subtitleIndex;

@property (nonatomic) AVCodecContext *subtitleCodecCtx;
/**
 初始化解码器
 
 @param baseCoder 基础
 @return 解码器
 */
+ (YLT_SubtitleDecoder *)decoderWithBaseDecoder:(YLT_BaseDecoder *)baseCoder;

/**
 打开字幕流

 @return 结果
 */
- (BOOL)YLT_OpenSubtitle;

/**
 处理字幕帧

 @return 字幕帧
 */
- (YLT_SubtitleFrame *)handleSubtitleFrame:(AVSubtitle *)pSubtitle;
/**
 关闭字幕流

 @return 结果
 */
- (BOOL)YLT_CloseSubtitle;

@end
