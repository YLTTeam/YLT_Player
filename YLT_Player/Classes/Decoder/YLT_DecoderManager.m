//
//  YLT_DecoderManager.m
//  FMDB
//
//  Created by Alex on 2017/11/26.
//

#import "YLT_DecoderManager.h"

@interface YLT_DecoderManager() {
}

@end

@implementation YLT_DecoderManager

/**
 解码器打开文件
 
 @param filePath 文件路径
 */
- (void)YLT_OpenFile:(NSString *)filePath {
    if (![self.baseDecoder YLT_OpenFile:filePath]) {
        return ;
    }
    if (![self.baseDecoder findStreams]) {
        return;
    }
    //打开视频、音频、字幕流
    self.videoDecoder.videoIndex = -1;
    self.audioDecoder.audioIndex = -1;
    self.subtitleDecoder.subtitleIndex = -1;
    if ([self.videoDecoder YLT_OpenVideo] && [self.audioDecoder YLT_OpenAudio] && [self.subtitleDecoder YLT_OpenSubtitle]) {
        [self.baseDecoder decodeDuration:0];
    } else {
        [self closeFile];
    }
}

- (void)closeFile {
    //TODO:
}


#pragma mark - setter getter

- (NSInteger)videoStreamIndex {
    return self.videoDecoder.videoIndex;
}

- (NSInteger)audioStreamIndex {
    return self.audioDecoder.audioIndex;
}

- (NSInteger)subtitleStreamIndex {
    return self.subtitleDecoder.subtitleIndex;
}

- (void)setVideoStreamIndex:(NSInteger)videoStreamIndex {
    self.videoDecoder.videoIndex = videoStreamIndex;
}

- (void)setAudioStreamIndex:(NSInteger)audioStreamIndex {
    self.audioDecoder.audioIndex = audioStreamIndex;
}

- (void)setSubtitleStreamIndex:(NSInteger)subtitleStreamIndex {
    self.subtitleDecoder.subtitleIndex = subtitleStreamIndex;
}

- (YLT_BaseDecoder *)baseDecoder {
    if (!_baseDecoder) {
        _baseDecoder = [YLT_BaseDecoder decoderWithDecoderManager:self];
    }
    return _baseDecoder;
}

- (YLT_VideoDecoder *)videoDecoder {
    if (!_videoDecoder) {
        _videoDecoder = [YLT_VideoDecoder decoderWithBaseDecoder:self.baseDecoder];
    }
    return _videoDecoder;
}

- (YLT_AudioDecoder *)audioDecoder {
    if (!_audioDecoder) {
        _audioDecoder = [YLT_AudioDecoder decoderWithBaseDecoder:self.baseDecoder];
    }
    return _audioDecoder;
}

- (YLT_SubtitleDecoder *)subtitleDecoder {
    if (!_subtitleDecoder) {
        _subtitleDecoder = [YLT_SubtitleDecoder decoderWithBaseDecoder:self.baseDecoder];
    }
    return _subtitleDecoder;
}

@end
