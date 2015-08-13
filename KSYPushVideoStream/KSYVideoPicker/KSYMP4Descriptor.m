//
//  KSYMP4Descriptor.m
//  ffmpeg-wrapper
//
//  Created by Blues on 10/18/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import "KSYMP4Descriptor.h"
#import "KSYBytesData.h"
#import "NSData+Hex.h"

const int kMP4ESDescriptorTag = 3;
const int kMP4DecoderConfigDescriptorTag = 4;
const int kMP4DecSpecificInfoDescriptorTag = 5;

@interface KSYMP4Descriptor () {
    
}

/**
 @abstract
 Loads the MP4ES_Descriptor from the input data.
 
 @param bytes data the input stream
 */
- (void)createESDescriptor:(KSYBytesData *)data;

/**
 @abstract
 Loads the MP4DecoderConfigDescriptor from the input data.
 
 @param bytes data the input stream
 */
- (void)createDecoderConfigDescriptor:(KSYBytesData *)data;

/**
 @abstract
 Loads the MP4DecSpecificInfoDescriptor from the input data.
 
 @param bytes data the input stream
 */
- (void)createDecSpecificInfoDescriptor:(KSYBytesData *)data;

@end

@implementation KSYMP4Descriptor

@synthesize size;
@synthesize type;
@synthesize read;
@synthesize children;
@synthesize decSpecificDataOffset;
@synthesize decSpecificDataSize;
@synthesize dsID;

+ (KSYMP4Descriptor *)createDescriptor:(KSYBytesData *)data {
    int tag = [data getInt8];
    int read = 1;
    int size = 0;
    int b = 0;
    do {
        b = [data getInt8];
        size <<= 7;
        size |= b & 0x7f;
        read++;
    } while ((b & 0x80) == 0x80);
    
    KSYMP4Descriptor *descriptor = [[KSYMP4Descriptor alloc] init];
    descriptor.type = tag;
    descriptor.size = size;
    switch (tag) {
        case kMP4ESDescriptorTag:
            [descriptor createESDescriptor:data];
            break;
        case kMP4DecoderConfigDescriptorTag:
            [descriptor createDecoderConfigDescriptor:data];
            break;
        case kMP4DecSpecificInfoDescriptorTag:
            [descriptor createDecSpecificInfoDescriptor:data];
            break;
        default:
            break;
    }
    [data skip:(descriptor.size - descriptor.read)];
    descriptor.read = read + descriptor.size;
    return descriptor;
}

- (id)init {
    self = [super init];
    if (self) {
        children = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    
}

- (void)createESDescriptor:(KSYBytesData *)data {
    int esID = [data getInt16];
    int flags = [data getInt8];
    BOOL streamDependenceFlag = (flags & (1 << 7)) != 0;
    BOOL urlFlag = (flags & (1 << 6)) != 0;
    BOOL ocrFlag = (flags & (1 << 5)) != 0;
    read += 3;
    if (streamDependenceFlag) {
        [data skip:2];
        read += 2;
    }
    if (urlFlag) {
        int strSize = [data getInt8];
        [data getString:strSize];
        read += strSize + 1;
    }
    if (ocrFlag) {
        [data skip:2];
        read += 2;
    }
    while (read < size) {
        KSYMP4Descriptor *descriptor = [KSYMP4Descriptor createDescriptor:data];
        if (!descriptor) {
            NSLog(@"Failed to create KSYMP4Descriptor");
            break;
        }
        [children addObject:descriptor];
        read += descriptor.read;
    }
}

- (void)createDecoderConfigDescriptor:(KSYBytesData *)data {
    int objectTypeIndication = [data getInt8];
    int value = [data getInt8];
    BOOL upstream = (value & (1 << 1)) > 0;
    Byte streamType = (Byte) (value >> 2);
    value = [data getInt16];
    int bufferSizeDB = value << 8;
    value = [data getInt8];
    bufferSizeDB |= value & 0xff;
    int maxBitRate = [data getInt32];
    int minBitRate = [data getInt32];
    read += 13;
    if (read < size) {
        KSYMP4Descriptor *descriptor = [KSYMP4Descriptor createDescriptor:data];
        if (!descriptor) {
            NSLog(@"Failed to create KSYMP4Descriptor");
        } else {
            [children addObject:descriptor];
            read += descriptor.read;
        }
    }
}

- (void)createDecSpecificInfoDescriptor:(KSYBytesData *)data {
    decSpecificDataOffset = data.position;
    NSMutableData *ds = [[NSMutableData alloc] init];
    Byte p = 0;
    for (int b = 0; b < size; b++) {
        p = [data getInt8];
        [ds appendBytes:&p length:1];
        read++;
    }
    decSpecificDataSize = size - read;
    self.dsID = ds;
}

@end
