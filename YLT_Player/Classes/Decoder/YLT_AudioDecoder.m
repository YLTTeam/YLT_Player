//
//  YLT_AudioDecoder.m
//  FMDB
//
//  Created by Alex on 2017/11/26.
//

#import "YLT_AudioDecoder.h"
#import "YLT_AudioManager.h"
#import <YLT_BaseLib/YLT_BaseLib.h>
#import "YLT_AudioManager.h"
#import <Accelerate/Accelerate.h>

@interface YLT_AudioDecoder() {
    SwrContext *_swrContext;//音频转换器
    void* _swrBuffer;
    NSUInteger _swrBufferSize;
    CGFloat _audioTimeBase;
}

@property (nonatomic, weak) YLT_BaseDecoder *baseDecoder;

@end

@implementation YLT_AudioDecoder

+ (void)initialize {
    id<YLT_AudioManager> audioManager = [YLT_AudioManager audioManager];
    [audioManager activateAudioSession];
}

/**
 初始化解码器
 
 @param baseCoder 基础
 @return 解码器
 */
+ (YLT_AudioDecoder *)decoderWithBaseDecoder:(YLT_BaseDecoder *)baseCoder {
    YLT_AudioDecoder *result = [[YLT_AudioDecoder alloc] init];
    result.baseDecoder = baseCoder;
    return result;
}

/**
 打开音频流
 
 @return 结果
 */
- (BOOL)YLT_OpenAudio {
    if (self.baseDecoder.audioStreams.count == 0) {
        return YES;
    }
    for (NSNumber *num in self.baseDecoder.audioStreams) {
        NSInteger iStream = num.integerValue;
        if ([self YLT_OpenAudioStreamIndex:iStream]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)YLT_OpenAudioStreamIndex:(NSInteger)iStream {
    //初始化音频解码器
    AVCodecContext *coderCtx = [self.baseDecoder findCoderForStreamIndex:iStream];
    SwrContext *swrContext = NULL;
    if (![self audioCodecIsSupported:coderCtx]) {
        id<YLT_AudioManager> audioManager = [YLT_AudioManager audioManager];
        //转化音频输出格式 保证音频输出格式可以播放
        swrContext = swr_alloc_set_opts(NULL,
                                        av_get_default_channel_layout(audioManager.numOutputChannels),
                                        AV_SAMPLE_FMT_S16,
                                        audioManager.samplingRate,
                                        av_get_default_channel_layout(coderCtx->channels),
                                        coderCtx->sample_fmt,
                                        coderCtx->sample_rate,
                                        0,
                                        NULL);
        if (!swrContext || swr_init(swrContext)) {
            if (swrContext) {
                swr_free(&swrContext);
            }
            avcodec_close(coderCtx);
            avcodec_free_context(&coderCtx);
            [self.baseDecoder YLT_Error:YLT_DecoderErrorCoderSwrFailed];
            return NO;
        }
    } else {
        [self.baseDecoder YLT_Error:YLT_DecoderErrorCoderUnsupported];
        return NO;
    }

    _audioFrame = av_frame_alloc();
    if (!_audioFrame) {
        if (swrContext) {
            swr_free(&swrContext);
        }
        avcodec_close(coderCtx);
        avcodec_free_context(&coderCtx);
        [self.baseDecoder YLT_Error:YLT_DecoderErrorAllocateFrame];
        return NO;
    }

    _audioIndex = iStream;
    _audioCodecCtx = coderCtx;
    _swrContext = swrContext;
    [self.baseDecoder stream:self.baseDecoder.formatCtx->streams[_audioIndex] defaultTimebase:0.025 fps:0 ptimebase:&_audioTimeBase];
    YLT_LogInfo(@"音频打开成功");
    return YES;
}

- (BOOL)audioCodecIsSupported:(AVCodecContext *)audioCtx {
    if (audioCtx->sample_fmt == AV_SAMPLE_FMT_S16) {
        id<YLT_AudioManager> audioManager = [YLT_AudioManager audioManager];
        return (int)audioManager.samplingRate == audioCtx->sample_rate &&
        audioManager.numOutputChannels == audioCtx->channels;
    }
    return NO;
}

/**
 处理音频帧
 
 @return 音频帧
 */
- (YLT_AudioFrame *)handleAudioFrame {
    if (!_audioFrame->data[0]) {
        return nil;
    }
    id<YLT_AudioManager> audioManager = [YLT_AudioManager audioManager];
    const NSUInteger numChannels = audioManager.numOutputChannels;
    NSInteger numFrames;
    void* audioData;
    if (_swrContext) {
        const NSUInteger ratio = MAX(1, audioManager.samplingRate / _audioCodecCtx->sample_rate)*
        MAX(1, audioManager.numOutputChannels / _audioCodecCtx->channels)* 2;
        const int bufSize = av_samples_get_buffer_size(NULL,
                                                       audioManager.numOutputChannels,
                                                       (int)(_audioFrame->nb_samples * ratio),
                                                       AV_SAMPLE_FMT_S16,
                                                       1);
        if (!_swrBuffer || _swrBufferSize < bufSize) {
            _swrBufferSize = bufSize;
            _swrBuffer = realloc(_swrBuffer, _swrBufferSize);
        }
        Byte *outbuf[2] = { _swrBuffer, 0 };
        numFrames = swr_convert(_swrContext,
                                outbuf,
                                (int)(_audioFrame->nb_samples * ratio),
                                (const uint8_t **)_audioFrame->data,
                                _audioFrame->nb_samples);
        if (numFrames < 0) {
            NSLog(@"fail resample audio");
            return nil;
        }
        //int64_t delay = swr_get_delay(_swrContext, audioManager.samplingRate);
        //if (delay > 0)
        //    NSLog(@"resample delay %lld", delay);
        audioData = _swrBuffer;
    } else {
        if (_audioCodecCtx->sample_fmt != AV_SAMPLE_FMT_S16) {
            NSAssert(false, @"bucheck, audio format is invalid");
            return nil;
        }
        audioData = _audioFrame->data[0];
        numFrames = _audioFrame->nb_samples;
    }
    const NSUInteger numElements = numFrames * numChannels;
    NSMutableData *data = [NSMutableData dataWithLength:numElements * sizeof(float)];
    float scale = 1.0 /(float)INT16_MAX ;
    vDSP_vflt16((SInt16 *)audioData, 1, data.mutableBytes, 1, numElements);
    vDSP_vsmul(data.mutableBytes, 1, &scale, data.mutableBytes, 1, numElements);
    YLT_AudioFrame *frame = [[YLT_AudioFrame alloc] init];
    frame.position = av_frame_get_best_effort_timestamp(_audioFrame)* _audioTimeBase;
    frame.duration = av_frame_get_pkt_duration(_audioFrame)* _audioTimeBase;
    frame.samples = data;
    if (frame.duration == 0) {
        frame.duration = frame.samples.length /(sizeof(float)* numChannels * audioManager.samplingRate);
    }
    
    YLT_LogInfo(@"AFD:%.4f %.4f | %.4f ", frame.position, frame.duration, frame.samples.length /(8.0 * 44100.0));
    return frame;
}

/**
 关闭流
 
 @return 结果
 */
- (BOOL)YLT_CloseAuio {
    return NO;
}
@end
