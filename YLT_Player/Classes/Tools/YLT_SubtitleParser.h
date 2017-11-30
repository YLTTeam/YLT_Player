//
//  YLT_SubtitleParser.h
//  FMDB
//
//  Created by Alex on 2017/11/26.
//

#import <Foundation/Foundation.h>

@interface YLT_SubtitleParser : NSObject

+ (NSArray *)parseEvents:(NSString *)events;
+ (NSArray *)parseDialogue:(NSString *)dialogue
                 numFields:(NSUInteger)numFields;
+ (NSString *)removeCommandsFromEventText:(NSString *)text;

@end
