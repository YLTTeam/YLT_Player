//
//  YLT_BaseDecoder.h
//  Pods
//
//  Created by Alex on 2017/11/26.
//

#import <Foundation/Foundation.h>
#import <YLT_FFMpeg/YLT_FFMpeg.h>
#import "YLT_DecoderFrame.h"
@class YLT_DecoderManager;

typedef NS_ENUM(NSUInteger, YLT_DecoderError) {
    YLT_DecoderErrorNone = 1000,//无错误回调
    YLT_DecoderErrorFilePathInvalid,//路径无效
    YLT_DecoderErrorAVFormatInitError,//avformat init error
    YLT_DecoderErrorOpenFailed,//open error
    YLT_DecoderErrorStreamInfoNotFound,//stream info not found
    YLT_DecoderErrorCoderNotFound,//解码器未找到
    YLT_DecoderErrorCoderOpenError,//解码器打开失败
    YLT_DecoderErrorCoderUnsupported,//编码器不支持
    YLT_DecoderErrorCoderSwrFailed,//音频转码失败
    YLT_DecoderErrorAllocateFrame,//初始化frame出错
    YLT_DecoderErrorUnknown,//未知错误
};


@interface YLT_BaseDecoder : NSObject

/**
 文件上下文
 */
@property (nonatomic) AVFormatContext *formatCtx;
/**
 是否结束
 */
@property (readonly, nonatomic) BOOL isEOF;
/**
 解码完成
 */
@property (readwrite, nonatomic) BOOL decodedFinish;
/**
 缓存中的frame
 */
@property (readwrite, nonatomic) NSMutableArray *decodedResult;

/**
 视频流
 */
@property (nonatomic, strong) NSMutableArray<NSNumber *> *videoStreams;
/**
 音频流
 */
@property (nonatomic, strong) NSMutableArray<NSNumber *> *audioStreams;
/**
 字幕流
 */
@property (nonatomic, strong) NSMutableArray<NSNumber *> *subtitleStreams;

/**
 播放的位置
 */
@property (nonatomic, assign) CGFloat position;

/**
 被中断的回调
 */
@property (nonatomic, copy) BOOL(^interruptCallback)(void);
/**
 异常回调
 */
@property (nonatomic, copy) void(^callback)(YLT_DecoderError error);


/**
 初始化解码器
 
 @param decoderManager 管理者
 @return 解码器
 */
+ (YLT_BaseDecoder *)decoderWithDecoderManager:(YLT_DecoderManager *)decoderManager;
/**
 打开文件
 
 @return 结果
 */
- (BOOL)YLT_OpenFile:(NSString *)filePath;
/**
 查找流

 @return 结果
 */
- (BOOL)findStreams;

/**
 根据索引查找解码器

 @param iStream 索引
 @return 解码器
 */
- (AVCodecContext *)findCoderForStreamIndex:(NSInteger)iStream;


/**
 解码帧

 @param minDuration 最小时间
 @return 数据内容
 */
- (NSArray *)decodeDuration:(CGFloat)minDuration;

/**
 获取timebase与fps

 @param st 流
 @param defaultTimeBase 默认timebase
 @param pFPS fps
 @param pTimeBase timebase
 @return 结果
 */
- (BOOL)stream:(AVStream *)st defaultTimebase:(CGFloat)defaultTimeBase fps:(CGFloat *)pFPS ptimebase:(CGFloat *)pTimeBase;

- (void)YLT_Error:(YLT_DecoderError)error;


@end
