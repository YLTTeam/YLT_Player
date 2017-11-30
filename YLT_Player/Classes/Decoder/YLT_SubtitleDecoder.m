//
//  YLT_SubtitleDecoder.m
//  FMDB
//
//  Created by Alex on 2017/11/26.
//

#import "YLT_SubtitleDecoder.h"
#import "YLT_SubtitleParser.h"
#import <YLT_BaseLib/YLT_BaseLib.h>

@interface YLT_SubtitleDecoder(){
    NSInteger _subtitleASSEvents;
}

@property (nonatomic, weak) YLT_BaseDecoder *baseDecoder;

@end

@implementation YLT_SubtitleDecoder


/**
 初始化解码器
 
 @param baseCoder 基础
 @return 解码器
 */
+ (YLT_SubtitleDecoder *)decoderWithBaseDecoder:(YLT_BaseDecoder *)baseCoder {
    YLT_SubtitleDecoder *result = [[YLT_SubtitleDecoder alloc] init];
    result.baseDecoder = baseCoder;
    return result;
}

- (BOOL)YLT_OpenSubtitle {
    if (self.baseDecoder.subtitleStreams.count == 0) {
        return YES;
    }
    for (NSNumber *num in self.baseDecoder.subtitleStreams) {
        NSInteger iStream = num.integerValue;
        if ([self YLT_OpenSubtitleStreamIndex:iStream]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)YLT_OpenSubtitleStreamIndex:(NSInteger)iStream {
    AVCodecContext *coderCtx = [self.baseDecoder findCoderForStreamIndex:iStream];
    const AVCodecDescriptor *codecDesc = avcodec_descriptor_get(coderCtx->codec_id);
    if (codecDesc &&(codecDesc->props & AV_CODEC_PROP_BITMAP_SUB)) {
        [self.baseDecoder YLT_Error:YLT_DecoderErrorCoderUnsupported];
        return NO;
    }
    _subtitleIndex = iStream;
    _subtitleCodecCtx = coderCtx;
    YLT_LogInfo(@"subtitle codec:'%s' mode:%d enc:%s", codecDesc->name, coderCtx->sub_charenc_mode, coderCtx->sub_charenc);
    _subtitleASSEvents = -1;
    if (coderCtx->subtitle_header_size) {
        NSString *s = [[NSString alloc] initWithBytes:coderCtx->subtitle_header
                                               length:coderCtx->subtitle_header_size
                                             encoding:NSASCIIStringEncoding];
        if (s.length) {
            NSArray *fields = [YLT_SubtitleParser parseEvents:s];
            if (fields.count && [fields.lastObject isEqualToString:@"Text"]) {
                _subtitleASSEvents = fields.count;
                YLT_LogInfo(@"subtitle ass events:%@", [fields componentsJoinedByString:@","]);
            }
        }
    }
    YLT_LogInfo(@"字幕打开成功");
    return YES;
}

/**
 处理字幕帧
 
 @return 字幕帧
 */
- (YLT_SubtitleFrame *)handleSubtitleFrame:(AVSubtitle *)pSubtitle {
    NSMutableString *ms = [NSMutableString string];
    for(NSUInteger i = 0; i < pSubtitle->num_rects; ++i) {
        AVSubtitleRect *rect = pSubtitle->rects[i];
        if (rect) {
            if (rect->text) { // rect->type == SUBTITLE_TEXT
                NSString *s = [NSString stringWithUTF8String:rect->text];
                if (s.length)[ms appendString:s];
            } else if (rect->ass && _subtitleASSEvents != -1) {
                NSString *s = [NSString stringWithUTF8String:rect->ass];
                if (s.length) {
                    NSArray *fields = [YLT_SubtitleParser parseDialogue:s numFields:_subtitleASSEvents];
                    if (fields.count && [fields.lastObject length]) {
                        s = [YLT_SubtitleParser removeCommandsFromEventText:fields.lastObject];
                        if (s.length)[ms appendString:s];
                    }
                }
            }
        }
    }
    if (!ms.length)
        return nil;
    YLT_SubtitleFrame *frame = [[YLT_SubtitleFrame alloc] init];
    frame.text = [ms copy];
    frame.position = pSubtitle->pts / AV_TIME_BASE + pSubtitle->start_display_time;
    frame.duration =(CGFloat)(pSubtitle->end_display_time - pSubtitle->start_display_time)/ 1000.f;

    YLT_LogInfo(@"SUB:%.4f %.4f | %@", frame.position, frame.duration, frame.text);
    return frame;
}

/**
 关闭字幕流
 
 @return 结果
 */
- (BOOL)YLT_CloseSubtitle {
    return NO;
}

@end
