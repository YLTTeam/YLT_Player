//
//  YLT_Player.m
//  Pods
//
//  Created by Alex on 2017/11/16.
//

#import "YLT_Player.h"
#import <YLT_BaseLib/YLT_BaseLib.h>
#import "YLT_Decoder.h"


@implementation YLT_Player

YLT_ShareInstance(YLT_Player);

- (void)YLT_init {
    
}

+ (void)YLT_OpenFile:(NSString *)filePath {
    if (![filePath YLT_CheckString]) {
        YLT_LogError(@"播放地址异常");
        return;
    }
    [[YLT_Decoder shareInstance] YLT_OpenFile:filePath];
    
    
}

    

@end
