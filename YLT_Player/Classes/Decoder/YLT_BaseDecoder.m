//
//  YLT_BaseDecoder.m
//  Pods
//
//  Created by Alex on 2017/11/26.
//

#import "YLT_BaseDecoder.h"
#import <YLT_BaseLib/YLT_BaseLib.h>
#import "YLT_DecoderManager.h"

static int interrupt_callback(void *ctx);

@interface YLT_BaseDecoder() {
    
}
/**
 文件路径
 */
@property (nonatomic, copy) NSString *filePath;
/**
 管理者
 */
@property (nonatomic, weak) YLT_DecoderManager *decoderManager;

@end


@implementation YLT_BaseDecoder

+ (void)initialize {
    av_register_all();//注册所有的组件
}

/**
 初始化解码器
 
 @param decoderManager 管理者
 @return 解码器
 */
+ (YLT_BaseDecoder *)decoderWithDecoderManager:(YLT_DecoderManager *)decoderManager {
    YLT_BaseDecoder *decoder = [[YLT_BaseDecoder alloc] init];
    decoder.decoderManager = decoderManager;
    return decoder;
}

/**
 检测文件的有效性
 
 @param filePath 文件路径
 @return 有效性
 */
- (BOOL)YLT_CheckFile:(NSString *)filePath {
    if (![filePath YLT_CheckString]) {//路径有效性检测
        [self YLT_Error:YLT_DecoderErrorFilePathInvalid];
        return NO;
    }
    //网络视频
    if ([filePath YLT_CheckURL]) {
        //网络初始化
        avformat_network_init();
    }
    
    return YES;
}

/**
 打开文件

 @return 结果
 */
- (BOOL)YLT_OpenFile:(NSString *)filePath {
    if (![self YLT_CheckFile:filePath]) {
        YLT_LogError(@"文件无效");
    }
    self.filePath = filePath;
    AVFormatContext *formatCtx = NULL;
    formatCtx = avformat_alloc_context();
    if (!formatCtx) {
        [self YLT_Error:YLT_DecoderErrorAVFormatInitError];
        return NO;
    }
    
    AVIOInterruptCB cb = {interrupt_callback, (__bridge void *)(self)};
    formatCtx->interrupt_callback = cb;
    
    if (avformat_open_input(&formatCtx, self.filePath.UTF8String, NULL, NULL) != 0) {
        [self YLT_Error:YLT_DecoderErrorOpenFailed];
        return NO;
    }
    if (avformat_find_stream_info(formatCtx, NULL) != 0) {
        avformat_close_input(&formatCtx);
        [self YLT_Error:YLT_DecoderErrorStreamInfoNotFound];
        return NO;
    }
#if DEBUG //打印流媒体信息 DEBUG模式打开
    av_dump_format(formatCtx, 0, [self.filePath.lastPathComponent cStringUsingEncoding:NSUTF8StringEncoding], false);
#endif
    _formatCtx = formatCtx;
    return YES;
}

/**
 根据索引查找解码器
 
 @param iStream 索引
 @return 解码器
 */
- (AVCodecContext *)findCoderForStreamIndex:(NSInteger)iStream {
    //初始化视频解码器
    AVCodecContext *coderCtx = avcodec_alloc_context3(NULL);
    //拷贝对象
    avcodec_parameters_to_context(coderCtx, _formatCtx->streams[iStream]->codecpar);
    //查找视频解码器
    AVCodec *coderc = avcodec_find_decoder(coderCtx->codec_id);
    if (!coderc) {
        avcodec_free_context(&coderCtx);
        [self YLT_Error:YLT_DecoderErrorCoderNotFound];
        return nil;
    }
    //打开解码器
    if (avcodec_open2(coderCtx, coderc, NULL) != 0) {
        avcodec_free_context(&coderCtx);
        [self YLT_Error:YLT_DecoderErrorCoderOpenError];
        return nil;
    }
    return coderCtx;
}

/**
 解码帧
 
 @param minDuration 最小时间
 @return 数据内容
 */
- (NSArray *)decodeDuration:(CGFloat)minDuration {
    if (self.decoderManager.videoStreamIndex == -1 && self.decoderManager.videoStreamIndex == -1) {
        return nil;
    }
    _decodedResult = [NSMutableArray array];
    AVPacket packet;
    CGFloat decodedDuraion = 0;
    _decodedFinish = NO;
    while (!_decodedFinish) {
        if (av_read_frame(_formatCtx, &packet) < 0) {
            _isEOF = YES;
            break;
        }
        if (packet.stream_index == self.decoderManager.videoStreamIndex) {
            int ret = avcodec_send_packet(self.decoderManager.videoDecoder.videoCodecCtx, &packet);
            if (ret < 0 && ret != AVERROR(EAGAIN) && ret != AVERROR_EOF) {
                av_packet_unref(&packet);
                break;
            }
            ret = avcodec_receive_frame(self.decoderManager.videoDecoder.videoCodecCtx, self.decoderManager.videoDecoder.videoFrame);
            if (ret < 0 && ret != AVERROR(EAGAIN) && ret != AVERROR_EOF) {
                av_packet_unref(&packet);
                break;
            }
            YLT_VideoFrame *frame = [self.decoderManager.videoDecoder handleVideoFrame];
            if (frame) {
                [_decodedResult addObject:frame];
                self.position = frame.position;
                decodedDuraion  += frame.duration;
                if (decodedDuraion > minDuration) {
                    _decodedFinish = YES;
                }
            }
            
            if (self.decoderManager.videoDecoder.videoFrame->pict_type == AV_PICTURE_TYPE_I) {
                YLT_Log(@"videoFrame = %f", self.position);
            }
        } else if (packet.stream_index == self.decoderManager.audioStreamIndex) {
            int ret = avcodec_send_packet(self.decoderManager.audioDecoder.audioCodecCtx, &packet);
            if (ret < 0 && ret != AVERROR(EAGAIN) && ret != AVERROR_EOF) {
                av_packet_unref(&packet);
                break;
            }
            ret = avcodec_receive_frame(self.decoderManager.audioDecoder.audioCodecCtx, self.decoderManager.audioDecoder.audioFrame);
            if (ret < 0 && ret != AVERROR(EAGAIN) && ret != AVERROR_EOF) {
                av_packet_unref(&packet);
                break;
            }
            YLT_AudioFrame *frame = [self.decoderManager.audioDecoder handleAudioFrame];
            if (frame) {
                [_decodedResult addObject:frame];
                if (self.decoderManager.videoDecoder.videoIndex == -1) {//表明仅仅是音频
                    _position = frame.position;
                    decodedDuraion += frame.duration;
                    if (decodedDuraion > minDuration) {
                        _decodedFinish = YES;
                    }
                }
            }
        } else if (packet.stream_index == self.decoderManager.subtitleStreamIndex) {
            int pktSize = packet.size;
            while(pktSize > 0) {
                AVSubtitle subtitle;
                int gotsubtitle = 0;
                int len = avcodec_decode_subtitle2(self.decoderManager.subtitleDecoder.subtitleCodecCtx,
                                                   &subtitle,
                                                   &gotsubtitle,
                                                   &packet);
                
                if (len < 0) {
                    NSLog(@"decode subtitle error, skip packet");
                    break;
                }
                
                if (gotsubtitle) {
                    YLT_SubtitleFrame *frame = [self.decoderManager.subtitleDecoder handleSubtitleFrame:&subtitle];
                    if (frame) {
                        [_decodedResult addObject:frame];
                    }
                    avsubtitle_free(&subtitle);
                }
                
                if (0 == len)
                    break;
                
                pktSize -= len;
            }
        } else if (packet.stream_index == self.decoderManager.artworkStreamIndex) {
            if (packet.size) {
                YLT_ArtworkFrame *frame = [[YLT_ArtworkFrame alloc] init];
                frame.picture = [NSData dataWithBytes:packet.data length:packet.size];
                [_decodedResult addObject:frame];
            }
        }
        
        
        av_packet_unref(&packet);
    }
    
    return _decodedResult;
}


#pragma mark - tools

- (BOOL)stream:(AVStream *)st defaultTimebase:(CGFloat)defaultTimeBase fps:(CGFloat *)pFPS ptimebase:(CGFloat *)pTimeBase {
    CGFloat fps, timebase;
    AVCodecContext *codec = avcodec_alloc_context3(NULL);
    avcodec_parameters_to_context(codec, st->codecpar);
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else if (codec->time_base.den && codec->time_base.num)
        timebase = av_q2d(codec->time_base);
    else
        timebase = defaultTimeBase;
    
    if (codec->ticks_per_frame != 1) {
        //timebase *= st->codec->ticks_per_frame;
    }
    
    if (st->avg_frame_rate.den && st->avg_frame_rate.num)
        fps = av_q2d(st->avg_frame_rate);
    else if (st->r_frame_rate.den && st->r_frame_rate.num)
        fps = av_q2d(st->r_frame_rate);
    else
        fps = 1.0 / timebase;
    if (pFPS)
        *pFPS = fps;
    if (pTimeBase)
        *pTimeBase = timebase;
    avcodec_free_context(&codec);
    return YES;
}

- (void)YLT_Error:(YLT_DecoderError)error {
    if (_formatCtx) {
        avformat_free_context(_formatCtx);
    }
    
    if (error != YLT_DecoderErrorNone) {
        self.callback(error);
    }
}


- (BOOL)findStreams {
    for (NSInteger i = 0; i < _formatCtx->nb_streams; i++) {
        switch (_formatCtx->streams[i]->codecpar->codec_type) {
            case AVMEDIA_TYPE_VIDEO: {
                [self.videoStreams addObject:@(i)];
            }
                break;
            case AVMEDIA_TYPE_AUDIO: {
                [self.audioStreams addObject:@(i)];
            }
                break;
            case AVMEDIA_TYPE_SUBTITLE: {
                [self.subtitleStreams addObject:@(i)];
            }
                break;
                
            default:
                break;
        }
    }
    return YES;
}

#pragma mark - setter getter


- (NSMutableArray<NSNumber *> *)videoStreams {
    if (_videoStreams == nil) {
        _videoStreams = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return _videoStreams;
}

- (NSMutableArray<NSNumber *> *)audioStreams {
    if (_audioStreams == nil) {
        _audioStreams = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return _audioStreams;
}

- (NSMutableArray<NSNumber *> *)subtitleStream {
    if (_subtitleStreams == nil) {
        _subtitleStreams = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return _subtitleStreams;
}

- (BOOL)interruptDecoder {
    if (_interruptCallback)
        return _interruptCallback();
    return NO;
}

- (BOOL(^)(void))interruptCallback {
    if (_interruptCallback == nil) {
        _interruptCallback = ^BOOL(void) {
            //TODO:接收到中断 可做默认处理
            
            return YES;
        };
    }
    return _interruptCallback;
}

- (void(^)(YLT_DecoderError error))callback {
    if (_callback == nil) {
        _callback = ^(YLT_DecoderError error){
            //TODO: 接收到错误做默认的处理
            YLT_Log(@"----->>>decoder error %zd <<<<<-----", error);
        };
    }
    return _callback;
}


@end


static int interrupt_callback(void *ctx) {
    if (!ctx)
        return 0;
    __unsafe_unretained YLT_BaseDecoder *p =(__bridge YLT_BaseDecoder *)ctx;
    const BOOL r = [p interruptDecoder];
    if (r) YLT_Log(@"DEBUG:INTERRUPT_CALLBACK!");
    return r;
}
