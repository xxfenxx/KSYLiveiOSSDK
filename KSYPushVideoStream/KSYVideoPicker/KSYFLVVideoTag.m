//
//  KSYFLVVideoTag.m
//  protos
//
//  Created by Blues on 10/18/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import "KSYFLVVideoTag.h"
#import "KSYFLVTag.h"

@implementation KSYFLVVideoTag

@synthesize packetType;
@synthesize codecId;
@synthesize frameType;
@synthesize body;
@synthesize cts;

- (id)init {
    self = [super init];
    if (self) {
        packetType = kAVCNALU;
        codecId = kFLVCodecIdH264;
        frameType = FLV_FRAME_INTER;
        self.dataType = kFLVTagTypeVideo;
        self.flagsSize = 5;
        self.cts = 0;
    }
    return self;
}

@end
