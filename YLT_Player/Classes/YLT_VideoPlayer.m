//
//  YLT_VideoPlayer.m
//  Pods
//
//  Created by Alex on 2017/11/25.
//

#import "YLT_VideoPlayer.h"
#import "YLT_DecoderManager.h"

@interface YLT_VideoPlayer() {
}

@property (nonatomic, readonly) AVFormatContext *formatCtx;
/**
 解码器管理
 */
@property (nonatomic, strong) YLT_DecoderManager *decoderMgr;

@end


@implementation YLT_VideoPlayer

+ (YLT_VideoPlayer *)YLT_OpenFile:(NSString *)filePath {
    YLT_VideoPlayer *player = [[YLT_VideoPlayer alloc] init];
    player.decoderMgr = [[YLT_DecoderManager alloc] init];
    [player.decoderMgr YLT_OpenFile:filePath];
    return player;
}



#pragma mark - setter getter

- (CGFloat)duration {
    if (!self.formatCtx) {
        return 0;
    }
    if (self.formatCtx->duration == AV_NOPTS_VALUE) {
        return MAXFLOAT;
    }
    return (CGFloat)self.formatCtx->duration/AV_TIME_BASE;
}

- (CGFloat)position {
    return _position;
}


- (AVFormatContext *)formatCtx {
    return self.decoderMgr.baseDecoder.formatCtx;
}

@end
