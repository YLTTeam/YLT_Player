//
//  YLT_Player.h
//  Pods
//
//  Created by Alex on 2017/11/16.
//

#import <Foundation/Foundation.h>
#import <YLT_BaseLib/YLT_BaseLib.h>

typedef NS_ENUM(NSUInteger, YLT_PlayerError) {
    YLT_PlayerError_OpenFile,//打开文件失败
    YLT_PlayerError_StreamNotFound,//音视频流未找到
    YLT_PlayerError_CodecNotFound,//编码器未找到
};

@interface YLT_Player : NSObject

YLT_ShareInstanceHeader(YLT_Player);

/**
 错误的回调
 */
@property (nonatomic, copy) void(^callback)(YLT_PlayerError error, NSString *errorMsg);

/**
 是否静音
 */
@property (nonatomic, assign) BOOL mute;

/**
 是否正在播放
 */
@property (nonatomic, assign) BOOL isPlaying;

/**
  全局配置
*/
+ (void)YLT_Configure;
    
/**
 打开文件
     
 @param filePath 文件路径
*/
+ (void)YLT_OpenFile:(NSString *)filePath;
    
@end
