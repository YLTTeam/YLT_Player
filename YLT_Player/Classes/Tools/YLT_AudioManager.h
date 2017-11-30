//
//  YLT_AudioManager.h
//  Pods
//
//  Created by 項普華 on 2017/1/10.
//  邮箱: xiangpuhua@126.com
//  电话: +86 13316987488
//  主页: https://github.com/xphaijj
//  Copyright © 2017年 項普華. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YLT_BaseLib/YLT_BaseLib.h>

typedef void (^YLT_AudioManagerOutputBlock)(float *data, UInt32 numFrames, UInt32 numChannels);

@protocol YLT_AudioManager <NSObject>

@property (readonly) UInt32             numOutputChannels;
@property (readonly) Float64            samplingRate;
@property (readonly) UInt32             numBytesPerSample;
@property (readonly) Float32            outputVolume;
@property (readonly) BOOL               playing;
@property (readonly, strong) NSString   *audioRoute;

@property (readwrite, copy) YLT_AudioManagerOutputBlock outputBlock;

- (BOOL)activateAudioSession;
- (void)deactivateAudioSession;
- (BOOL)play;
- (void)pause;

@end

@interface YLT_AudioManager : NSObject

+ (id<YLT_AudioManager>)audioManager;

@end
