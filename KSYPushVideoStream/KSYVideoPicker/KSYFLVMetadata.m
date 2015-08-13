//
//  KSYFLVMetadata.m
//  protos
//
//  Created by Blues on 10/11/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import "KSYFLVMetadata.h"

@implementation KSYFLVMetadata

@synthesize duration;
@synthesize width;
@synthesize height;
@synthesize videoBitrate;
@synthesize framerate;
@synthesize videoCodecId;
@synthesize audioBitrate;
@synthesize sampleRate;
@synthesize sampleSize;
@synthesize stereo;
@synthesize audioCodecId;

- (id)init {
    self = [super init];
    if (self) {
        audioCodecId = -1;
        videoCodecId = -1;
    }
    return self;
}

@end
