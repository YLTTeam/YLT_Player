//
//  YLT_Player.h
//  Pods
//
//  Created by Alex on 2017/11/16.
//

#import <Foundation/Foundation.h>

@interface YLT_Player : NSObject

/**
  全局配置
*/
+ (void)YLT_PlayerConfigure;
    
/**
 打开文件
     
 @param filePath 文件路径
*/
+ (void)YLT_PlayerOpenFile:(NSString *)filePath;
    
@end
