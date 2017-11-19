//
//  YLT_Player.m
//  Pods
//
//  Created by Alex on 2017/11/16.
//

#import "YLT_Player.h"

#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>


@implementation YLT_Player

+ (void)YLT_PlayerConfigure {
    const char *configuration = avcodec_configuration();
}

+ (void)YLT_PlayerOpenFile:(NSString *)filePath {
    //第一步：注册组件
    av_register_all();
    
    //第二步：打开封装格式文件
    //参数一：封装格式上下文
    AVFormatContext* avformat_context = avformat_alloc_context();
    //参数二：打开视频地址->path
    const char *url = [filePath UTF8String];
    //参数三：指定输入封装格式->默认格式
    //参数四：指定默认配置信息->默认配置
    int avformat_open_input_reuslt = avformat_open_input(&avformat_context, url, NULL, NULL);
    if (avformat_open_input_reuslt != 0){
        NSLog(@"打开文件失败");
        return;
    }
}

    

@end
