//
//  YLT_Decoder.h
//  Pods
//
//  Created by Alex on 2017/11/20.
//

#import <Foundation/Foundation.h>
#import <YLT_BaseLib/YLT_BaseLib.h>

@interface YLT_Decoder : NSObject

YLT_ShareInstanceHeader(YLT_Decoder);

- (void)YLT_OpenFile:(NSString *)filePath;

@end
