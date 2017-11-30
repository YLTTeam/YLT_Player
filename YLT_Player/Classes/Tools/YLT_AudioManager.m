//
//  YLT_AudioManager.m
//  Pods
//
//  Created by 項普華 on 2017/1/10.
//  邮箱: xiangpuhua@126.com
//  电话: +86 13316987488
//  主页: https://github.com/xphaijj
//  Copyright © 2017年 項普華. All rights reserved.
//

#import "YLT_AudioManager.h"
#import "TargetConditionals.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

static BOOL checkError(OSStatus error, const char *operation);
static OSStatus renderCallback (void *inRefCon, AudioUnitRenderActionFlags    *ioActionFlags, const AudioTimeStamp * inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData);

@interface YLT_AudioManagerImpl : YLT_AudioManager<YLT_AudioManager> {
    BOOL                        _initialized;
    BOOL                        _activated;
    float                       *_outData;
    AudioUnit                   _audioUnit;
    AudioStreamBasicDescription _outputFormat;
}

@property (readonly) UInt32             numOutputChannels;
@property (readonly) Float64            samplingRate;
@property (readonly) UInt32             numBytesPerSample;
@property (readwrite) Float32           outputVolume;
@property (readonly) BOOL               playing;
@property (readonly, strong) NSString   *audioRoute;

@property (readwrite, copy) YLT_AudioManagerOutputBlock outputBlock;
@property (readwrite) BOOL playAfterSessionEndInterruption;

- (BOOL) activateAudioSession;
- (void) deactivateAudioSession;
- (BOOL) play;
- (void) pause;

- (BOOL) checkAudioRoute;
- (BOOL) setupAudio;
- (BOOL) checkSessionProperties;
- (BOOL) renderFrames: (UInt32) numFrames
               ioData: (AudioBufferList *) ioData;
@end

@implementation YLT_AudioManager

+ (id<YLT_AudioManager>)audioManager {
    static YLT_AudioManagerImpl *audioManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        audioManager = [[YLT_AudioManagerImpl alloc] init];
    });
    return audioManager;
}

@end

@implementation YLT_AudioManagerImpl

- (id)init {
    self = [super init];
    if (self) {
        _outData = (float *)calloc(8192, sizeof(float));
        _outputVolume = 0.5;
    }
    return self;
}

- (void)dealloc {
    if (_outData) {
        free(_outData);
        _outData = NULL;
    }
}

#pragma mark - private

- (BOOL) checkAudioRoute {
    // Check what the audio route is.
    AVAudioSession * ses = [AVAudioSession sharedInstance];
    return ses.currentRoute.outputs.count > 0;
}

- (BOOL) setupAudio {
    // --- Audio Session Setup ---
    NSError * err = nil;
    AVAudioSession * ses = [AVAudioSession sharedInstance];
    [ses setCategory:AVAudioSessionCategoryPlayback error:&err];
    if ( err != nil ) {
        NSLog(@"Set Category playback error: %@", err);
        return NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleRouteChange:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object: ses];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleVolumnChange:)
                                                 name: @"AVSystemController_SystemVolumeDidChangeNotification"
                                               object: ses];
    
#if !TARGET_IPHONE_SIMULATOR
    Float32 preferredBufferSize = 0.0232;
    [ses setPreferredIOBufferDuration:preferredBufferSize error:&err];
    if ( err != nil ) {
        NSLog(@"Set preferredBufferSize error: %@", err);
    }
#endif
    [ses setActive:YES error:&err];
    if ( err != nil ) {
        NSLog(@"Couldn't activate the audio session: %@", err);
        return NO;
    }
    [self checkSessionProperties];
    // ----- Audio Unit Setup -----
    // Describe the output unit.
    
    AudioComponentDescription description = {0};
    description.componentType = kAudioUnitType_Output;
    description.componentSubType = kAudioUnitSubType_RemoteIO;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    // Get component
    AudioComponent component = AudioComponentFindNext(NULL, &description);
    if (checkError(AudioComponentInstanceNew(component, &_audioUnit),
                   "Couldn't create the output audio unit"))
        return NO;
    UInt32 size;
    
    // Check the output stream format
    size = sizeof(AudioStreamBasicDescription);
    if (checkError(AudioUnitGetProperty(_audioUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input,
                                        0,
                                        &_outputFormat,
                                        &size),
                   "Couldn't get the hardware output stream format"))
        return NO;
    _outputFormat.mSampleRate = _samplingRate;
    if (checkError(AudioUnitSetProperty(_audioUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Input,
                                        0,
                                        &_outputFormat,
                                        size),
                   "Couldn't set the hardware output stream format")) {
        // just warning
    }
    
    _numBytesPerSample = _outputFormat.mBitsPerChannel / 8;
    _numOutputChannels = _outputFormat.mChannelsPerFrame;
    NSLog(@"Current output bytes per sample: %u", (unsigned int)_numBytesPerSample);
    NSLog(@"Current output num channels: %u", (unsigned int)_numOutputChannels);
    // Slap a render callback on the unit
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = renderCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    if (checkError(AudioUnitSetProperty(_audioUnit,
                                        kAudioUnitProperty_SetRenderCallback,
                                        kAudioUnitScope_Input,
                                        0,
                                        &callbackStruct,
                                        sizeof(callbackStruct)),
                   "Couldn't set the render callback on the audio unit"))
        return NO;
    
    if (checkError(AudioUnitInitialize(_audioUnit),
                   "Couldn't initialize the audio unit"))
        return NO;
    return YES;
}

- (BOOL) checkSessionProperties {
    [self checkAudioRoute];
    // Check the number of output channels.
    UInt32 newNumChannels;
    AVAudioSession * ses = [AVAudioSession sharedInstance];
    newNumChannels = (UInt32)[ses outputNumberOfChannels];
    NSLog(@"We've got %u output channels", (unsigned int)newNumChannels);
    // Get the hardware sampling rate. This is settable, but here we're only reading.
    _samplingRate = [ses sampleRate];
    _outputVolume = [ses outputVolume];
    return YES;
}

- (BOOL)renderFrames:(UInt32)numFrames
ioData:(AudioBufferList *)ioData {
    for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
        memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    if (_playing && _outputBlock ) {
        // Collect data to render from the callbacks
        _outputBlock(_outData, numFrames, _numOutputChannels);
        // Put the rendered data into the output buffer
        if (_numBytesPerSample == 4) // then we've already got floats
            {
            float zero = 0.0;
            for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                for (int iChannel = 0; iChannel < thisNumChannels; ++iChannel) {
                    vDSP_vsadd(_outData+iChannel, _numOutputChannels, &zero, (float *)ioData->mBuffers[iBuffer].mData, thisNumChannels, numFrames);
                }
            }
            }
        else if (_numBytesPerSample == 2) // then we need to convert SInt16 -> Float (and also scale)
            {
            float scale = (float)INT16_MAX;
            vDSP_vsmul(_outData, 1, &scale, _outData, 1, numFrames*_numOutputChannels);
            for (int iBuffer=0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
                int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                for (int iChannel = 0; iChannel < thisNumChannels; ++iChannel) {
                    vDSP_vfix16(_outData+iChannel, _numOutputChannels, (SInt16 *)ioData->mBuffers[iBuffer].mData+iChannel, thisNumChannels, numFrames);
                }
            }
            }
    }
    
    return noErr;
}

#pragma mark - public
- (BOOL)activateAudioSession {
    if (!_activated) {
        if (!_initialized) {
            [[NSNotificationCenter defaultCenter] addObserver: self
                                                     selector: @selector(handleInterruption:)
                                                         name: AVAudioSessionInterruptionNotification
                                                       object: nil];
            _initialized = YES;
        }
        if ([self checkAudioRoute] &&
            [self setupAudio]) {
            _activated = YES;
        }
    }
    return _activated;
}

- (void) deactivateAudioSession {
    if (_activated) {
        [self pause];
        checkError(AudioUnitUninitialize(_audioUnit),
                   "Couldn't uninitialize the audio unit");
        checkError(AudioComponentInstanceDispose(_audioUnit),
                   "Couldn't dispose the output audio unit");
        NSError * err = nil;
        if ( ![[AVAudioSession sharedInstance] setActive:NO error:&err] || err != nil )
            NSLog(@"Couldn't deactivate the audio session: %@", err);
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
        if ( _initialized ) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
            _initialized = FALSE;
        }
        _activated = NO;
    }
}

- (void) pause {
    if (_playing) {
        _playing = checkError(AudioOutputUnitStop(_audioUnit),
                              "Couldn't stop the output unit");
        AudioUnitUninitialize(_audioUnit);
    }
}

- (BOOL) play {
    if (!_playing) {
        if ([self activateAudioSession]) {
            _playing = !checkError(AudioOutputUnitStart(_audioUnit),
                                   "Couldn't start the output unit");
        }
    }
    return _playing;
}

-(void)handleRouteChange:(NSNotification *)notification{
    if ( [self checkAudioRoute] )
        [self checkSessionProperties];
}

-(void)handleVolumnChange:(NSNotification *)notification{
    float volume = [[[notification userInfo]
                     objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"]
                    floatValue];
    self.outputVolume = volume;
}

-(void)handleInterruption:(NSNotification*)notification{
    NSInteger reason = 0;
    if ([notification.name isEqualToString:@"AVAudioSessionInterruptionNotification"]) {
        //Posted when an audio interruption occurs.
        reason = [[[notification userInfo] objectForKey:@" AVAudioSessionInterruptionTypeKey"] integerValue];
        if (reason == AVAudioSessionInterruptionTypeBegan) {
            NSLog(@"Begin interuption");
            self.playAfterSessionEndInterruption = self.playing;
            [self pause];
        }
        if (reason == AVAudioSessionInterruptionTypeEnded) {
            NSLog(@"End interuption");
            if (self.playAfterSessionEndInterruption) {
                self.playAfterSessionEndInterruption = NO;
                [self play];
            }
        }
    }
}

@end

#pragma mark - callbacks

static OSStatus renderCallback (void                        *inRefCon,
                                AudioUnitRenderActionFlags    * ioActionFlags,
                                const AudioTimeStamp         * inTimeStamp,
                                UInt32                        inOutputBusNumber,
                                UInt32                        inNumberFrames,
                                AudioBufferList                * ioData) {
    
    YLT_AudioManagerImpl *sm = (__bridge YLT_AudioManagerImpl *)inRefCon;
    return [sm renderFrames:inNumberFrames ioData:ioData];
}

static BOOL checkError(OSStatus error, const char *operation) {
    if (error == noErr)
        return NO;
    
    char str[20] = {0};
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    
    fprintf(stderr, "Error: %s (%s)\n", operation, str);
    
    //exit(1);
    return YES;
}
