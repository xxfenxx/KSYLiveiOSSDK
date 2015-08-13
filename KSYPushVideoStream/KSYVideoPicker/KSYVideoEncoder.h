//
//  KSYVideoEncoder.h
//  IFVideoPickerControllerDemo
//
//  Created by Blues on 3/27/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface KSYVideoEncoder : NSObject {
  
}

@property (nonatomic, retain) AVAssetWriterInput *assetWriterInput;
@property (nonatomic, assign) CMVideoDimensions dimensions;
@property (nonatomic, assign) CGFloat bitRate;
@property (nonatomic, assign) CGFloat maxKeyFrame;

/**
 @abstract
  create h264 video encoder with hardware acceleration by apple AVAssetWriter
 */
+ (KSYVideoEncoder *)createH264VideoWithDimensions:(CMVideoDimensions)dimensions
                                          bitRate:(CGFloat)bitRate
                                      maxKeyFrame:(CGFloat)maxKeyFrame;

@end
