//
//  KSYFLVAudioTag.m
//  protos
//
//  Created by Blues on 10/18/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import "KSYFLVAudioTag.h"
#import "KSYFLVTag.h"

@implementation KSYFLVAudioTag

@synthesize soundFormat;
@synthesize soundRate;
@synthesize soundSize;
@synthesize packetType;
@synthesize soundType;
@synthesize body;

- (id)init {
    self = [super init];
    if (self) {
        soundFormat = FLV_CODECID_AAC;
        soundRate = FLV_SAMPLERATE_44100HZ;
        soundSize = FLV_SAMPLESSIZE_16BIT;
        soundType = FLV_STEREO;
        packetType = kAACRaw;
        self.dataType = kFLVTagTypeAudio;
        self.flagsSize = 2;
    }
    return self;
}


@end
