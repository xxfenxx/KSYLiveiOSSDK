//
//  KSYVideoPicker.h
//  IFVideoPickerControllerDemo
//
//  Created by Blues on 3/25/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AVFoundation/AVCaptureSession.h"
#import "AVFoundation/AVCaptureOutput.h"
#import "AVFoundation/AVCaptureDevice.h"
#import "AVFoundation/AVCaptureInput.h"
#import "AVFoundation/AVCaptureVideoPreviewLayer.h"
#import "AVFoundation/AVMediaFormat.h"
#import "KSYAVAssetEncoder.h"
#import "KSYAudioEncoder.h"
#import "KSYVideoEncoder.h"
#import "KSYMP4Frame.h"

typedef void (^captureHandler)(CMSampleBufferRef sampleBuffer, IFCapturedBufferType type);

@interface KSYVideoPicker : NSObject {
  
}

@property (nonatomic, retain) AVCaptureDeviceInput *videoInput;
@property (nonatomic, retain) AVCaptureDeviceInput *audioInput;
@property (nonatomic, retain) AVCaptureVideoDataOutput *videoBufferOutput;
@property (nonatomic, retain) AVCaptureAudioDataOutput *audioBufferOutput;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, retain) UIView *videoPreviewView;
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;
@property (nonatomic, assign, getter = getEncoderState) BOOL isCapturing;

- (BOOL)startup;

- (void)shutdown;

/**
 @abstract
 start preview of camera input
 
 @param captureOutput
 
 */
- (void)startPreview:(UIView *)view;

- (void)startPreview:(UIView *)view withFrame:(CGRect)frame
         orientation:(AVCaptureVideoOrientation)orientation;


/**
 @abstract
 start capture YUV format video and audio stream from camera device. It returns
 captured raw buffer as form of CMSampleBufferRef through captureBlock.
 */
// - (void)startCaptureWithBlock:(captureHandler)captureBlock;

/**
 @abstract
 start capture YUV format video and audio stream from camera device. It returns
 encoded format of video and audio output through captureBlock.
 */
- (void)startCaptureWithEncoder:(KSYVideoEncoder *)video
                          audio:(KSYAudioEncoder *)audio
                   captureBlock:(encodedCaptureHandler)captureBlock
                metaHeaderBlock:(encodingMetaHeaderHandler)metaHeaderBlock
                   failureBlock:(encodingFailureHandler)failureBlock;

/*
 @depricated
- (void)startCaptureToFileWithEncoder:(KSYVideoEncoder *)video
                                audio:(KSYAudioEncoder *)audio
                              maxSize:(UInt64)maxSize
                        progressBlock:(encodedProgressHandler)progressBlock;
*/
/**
 */
- (void)stopCapture;

/**
 */
- (void)stopPreview;


@end
