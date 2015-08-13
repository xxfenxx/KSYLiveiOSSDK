//
//  KSYPushVideoStream.h
//  KSYPushVideoStream
//
//  Created by Blues on 15/7/9.
//  Copyright (c) 2015年 Blues. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^PushVideoStreamBlock)(double speed);
@interface KSYPushVideoStream : NSObject

+ (KSYPushVideoStream *)initialize;

@property (nonatomic, copy)PushVideoStreamBlock pushVideoStreamBlock;

- (instancetype)initWithDisplayView:(UIView *)displayView andCaptureDevicePosition:(AVCaptureDevicePosition)iCameraType;
- (void)startRecord;
- (void)stopRecord;
- (void)setUrl:(NSString *)strUrl;
- (void)setCameraType:(AVCaptureDevicePosition)iCameraType;
- (void)setVoiceType:(NSInteger)iVoiceType;
- (void)setAudioEncodeConfig:(NSInteger)audioSampleRate audioBitRate:(NSInteger)audioBitRate;
- (void)setVideoEncodeConfig:(NSInteger)videoFrameRate videoBitRate:(NSInteger)videoBitRate;
- (void)setVideoResolutionWithWidth:(CGFloat)videoWidth andHeight:(CGFloat)Height;
- (void)setDropFrameFrequency:(NSInteger)frequency;
- (NSInteger)networkSatusType;
- (BOOL)isCapturing;

@end
