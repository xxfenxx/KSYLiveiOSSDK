//
//  KSYAudioEncoder.h
//  IFVideoPickerControllerDemo
//
//  Created by Blues on 3/27/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface KSYAudioEncoder : NSObject {
  
}

@property (nonatomic, retain) AVAssetWriterInput *assetWriterInput;
@property (nonatomic, assign) CGFloat bitRate;
@property (nonatomic, assign) CGFloat sampleRate;
@property (nonatomic, assign) NSInteger codec;

/**
 @abstract
  create AAC audio encoder with hardware acceleration by apple AVAssetWriter
 */
+ (KSYAudioEncoder *)createAACAudioWithBitRate:(CGFloat)bitRate
                                   sampleRate:(CGFloat)sampleRate;

/**
 @abstract
  setup AVAssetWriteInput with the given audio description
 */
- (void)setupWithFormatDescription:(CMFormatDescriptionRef)formatDescription;

@end
