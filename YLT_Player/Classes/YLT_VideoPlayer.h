//
//  YLT_VideoPlayer.h
//  Pods
//
//  Created by Alex on 2017/11/25.
//

#import <Foundation/Foundation.h>

@interface YLT_VideoPlayer : NSObject

/**
 时长
 */
@property (nonatomic, assign, readonly) CGFloat duration;
/**
 播放的当前位置 时间 单位秒
 */
@property (nonatomic, assign, readwrite) CGFloat position;
/**
 视频宽度
 */
@property (nonatomic, assign, readonly) CGFloat frameWidth;
/**
 视频高度
 */
@property (nonatomic, assign, readonly) CGFloat frameHeight;
/**
 音频采样率
 */
@property (nonatomic, assign, readonly) CGFloat sampleRate;
/**
 声音流的数量 （粤语、中文）
 */
@property (nonatomic, assign, readonly) NSUInteger audioStreamCount;
/**
 选择的音频流索引
 */
@property (nonatomic, assign, readwrite) NSInteger selectedAudioStream;
/**
 字幕流的数量
 */
@property (nonatomic, assign, readonly) NSUInteger subtitleStreamCount;
/**
 选择的字幕流索引
 */
@property (nonatomic, assign, readwrite) NSInteger selectedSubtitleStream;
/**
 音频的有效性
 */
@property (nonatomic, assign, readonly) BOOL validAudio;
/**
 视频的有效性
 */
@property (nonatomic, assign, readonly) BOOL validVideo;
/**
 字幕的有效性
 */
@property (nonatomic, assign, readonly) BOOL validSubtitle;

/**
 更多信息
 */
@property (nonatomic, strong, readonly) NSDictionary *info;

+ (YLT_VideoPlayer *)YLT_OpenFile:(NSString *)filePath;


@end
