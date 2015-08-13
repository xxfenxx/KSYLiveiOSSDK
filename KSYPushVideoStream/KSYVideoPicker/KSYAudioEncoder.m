//
//  KSYAudioEncoder.m
//  IFVideoPickerControllerDemo
//
//  Created by Blues on 3/27/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import "KSYAudioEncoder.h"

@interface KSYAudioEncoder () {
}

@end

@implementation KSYAudioEncoder

@synthesize assetWriterInput;
@synthesize sampleRate;
@synthesize bitRate;
@synthesize codec;

+ (KSYAudioEncoder *)createAACAudioWithBitRate:(CGFloat)bitRate
                                    sampleRate:(CGFloat)sampleRate {
    KSYAudioEncoder *encoder = [[KSYAudioEncoder alloc] init];
    encoder.bitRate = bitRate;
    encoder.sampleRate = sampleRate;
    encoder.codec = kAudioFormatMPEG4AAC;
    [encoder setupWithFormatDescription:nil];
    return encoder;
}

- (void)setupWithFormatDescription:(CMFormatDescriptionRef)formatDescription {
    /*
     const AudioStreamBasicDescription *asbd =
     CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
     size_t aclSize = 0;
     const AudioChannelLayout *channelLayout =
     CMAudioFormatDescriptionGetChannelLayout(formatDescription, &aclSize);
     NSData *channelLayoutData = nil;
     
     // AVChannelLayoutKey must be specified, but if we don't know any better
     // give an empty data and let AVAssetWriter decide.
     if (channelLayout && aclSize > 0)
     channelLayoutData = [NSData dataWithBytes:channelLayout length:aclSize];
     else
     */
    NSData *channelLayoutData = [NSData data];
    
    NSDictionary *audioCompressionSettings =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithInteger:codec], AVFormatIDKey,
     [NSNumber numberWithFloat:sampleRate], AVSampleRateKey,
     [NSNumber numberWithInt:bitRate], AVEncoderBitRatePerChannelKey,
     [NSNumber numberWithInteger:1], AVNumberOfChannelsKey,
     channelLayoutData, AVChannelLayoutKey,
     nil];
    AVAssetWriterInput *newWriterInput =
    [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                   outputSettings:audioCompressionSettings];
    newWriterInput.expectsMediaDataInRealTime = YES;
    self.assetWriterInput = newWriterInput;
}

- (void)dealloc {
    
}

@end
