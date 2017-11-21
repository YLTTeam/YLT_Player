//
//  YLT_Decoder.m
//  Pods
//
//  Created by Alex on 2017/11/20.
//

#import "YLT_Decoder.h"
#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>

@interface YLT_Decoder() {
}
/**
 当前视频的路径
 */
@property (nonatomic, strong) NSString *currentVideoPath;
/**
 是否是网络视频
 */
@property (nonatomic, assign) BOOL isNetwork;

@end

@implementation YLT_Decoder

YLT_ShareInstance(YLT_Decoder);

- (void)YLT_init {
    const char *configuration = avcodec_configuration();
    YLT_Log(@"%s", configuration);
    //第一步：注册组件
    av_register_all();
    avformat_network_init();
}

- (void)YLT_OpenFile:(NSString *)filePath {
    
    //第二步：打开封装格式文件
    AVFormatContext* avformat_context = avformat_alloc_context();
    
    int err = avformat_open_input(&avformat_context, filePath.UTF8String, NULL, NULL);
    if (err != 0){
        YLT_LogWarn(@"打开文件失败 %d", err);
        return;
    }
    
    
    //第三步:查找音视频流
    
    //第四步:查找音视频解码器
    
    //第五步:打开解码器
    
    //第六步:循环读取音视频数据
    
    //第七步:视频解码
    
    //第八步:关闭解码器
}

@end
