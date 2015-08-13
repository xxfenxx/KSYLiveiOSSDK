//
//  KSYFLVWriter.m
//  protos
//
//  Created by Blues on 10/10/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import "KSYFLVWriter.h"
#import "KSYFLVHeader.h"
#import "KSYFLVTag.h"
#import "KSYFLVMetadata.h"
#import "KSYFLVVideoTag.h"
#import "KSYFLVAudioTag.h"
#import "NSData+Hex.h"
#import "NSMutableData+Bytes.h"
#import "NSMutableData+AMF.h"

@interface KSYFLVWriter () {
    NSUInteger previousTagSize_;
    int afterFrameKey_;
}

@property (atomic, retain) KSYFLVMetadata *metaTag;

@end

@implementation KSYFLVWriter

@synthesize packet;
@synthesize debug;
@synthesize metaTag;

// Length of the flv header in bytes
static const int kFlvHeaderLength = 9;

// Length of the flv tag in bytes
static const int kFlvTagHeaderLength = 11;

- (id)init {
    self = [super init];
    if (self) {
        packet = [[NSMutableData alloc] init];
        afterFrameKey_ = 0;
    }
    return self;
}

- (void)dealloc {
    
}

- (void)writeHeader {
    KSYFLVHeader *h = [[KSYFLVHeader alloc] init];
    h.flagVideo = YES;
    h.flagAudio = YES;
    NSData *header = [h write];
    [packet appendData:header];
    if (debug) {
        NSLog(@"FLV HEADER:\n%@", [header hexString]);
    }
}

- (void)writeTag:(KSYFLVTag *)tag {
    //
    // Tag header = 11 bytes
    // |-|---|----|---|
    //    0 = type
    //  1-3 = data size
    //  4-7 = timestamp
    //  8-10 = stream id (always 0)
    // Tag data = variable bytes
    // Previous tag = 4 bytes (tag header size + tag data size)
    //
    int bodySize = tag.bodySize;
    if (bodySize > 0) {
        // int tagSize = kFlvTagHeaderLength + bodySize + 4;
        int flags = 0;
        int flagsSize = tag.flagsSize;
        
        if (tag.dataType == kFLVTagTypeVideo) {
            // flags = kFLVCodecIdH264;
            // flags |= ((videoConfFrame || afterFrameKey_ > 0) ? FLV_FRAME_KEY : FLV_FRAME_INTER);
            // flags = kFLVCodecIdH264 | FLV_FRAME_INTER;
            // flagsSize = 5;
            /*
             if (videoConfFrame) {
             afterFrameKey_++;
             } else {
             afterFrameKey_ = 0;
             }
             */
            KSYFLVVideoTag *video = (KSYFLVVideoTag *)tag;
            flags = video.codecId | video.frameType;
        } else if (tag.dataType == kFLVTagTypeAudio) {
            // flags = FLV_CODECID_AAC | FLV_SAMPLERATE_44100HZ |
            //        FLV_SAMPLESSIZE_16BIT | FLV_STEREO;
            // flagsSize = 2;
            KSYFLVAudioTag *audio = (KSYFLVAudioTag *)tag;
            flags = audio.soundType |
            audio.soundSize |
            audio.soundFormat |
            audio.soundRate;
        }
        
        NSMutableData *buf =
        [[NSMutableData alloc] initWithCapacity:kFlvTagHeaderLength +
         bodySize + 4 + flagsSize];
        [buf putInt8:tag.dataType];                   // tag type META
        [buf putInt24:bodySize + flagsSize];          // size of data part
        [buf putInt24:tag.timestamp];
        // NSLog(@"tag.timestamp: %ld, tag.timestame >> 24: %ld", tag.timestamp, tag.timestamp >> 24);
        [buf putInt8:(tag.timestamp >> 24) & 0x7F];   // timestamp
        [buf putInt24:0];                             // reserved
        
        if (tag.dataType != kFLVTagTypeMeta) {
            [buf putInt8:flags];
            if (tag.dataType == kFLVTagTypeVideo &&
                metaTag.videoCodecId == kFLVCodecIdH264) {
                KSYFLVVideoTag *video = (KSYFLVVideoTag *)tag;
                [buf putInt8:video.packetType];  // AVC NALU
                [buf putInt24:video.cts]; // pts - dts
            } else if (tag.dataType == kFLVTagTypeAudio &&
                       metaTag.audioCodecId == kFLVCodecIdAAC) {
                // If aac body size is less than 3, we assume it is
                // AVCDecoderConfigurationRecord
                // See ISO 14496-15, 5.2.4.1 for the description of
                // AVCDecoderConfigurationRecord. This contains the same information
                // that would be stored in an avcC box in an MP4/FLV file.
                KSYFLVAudioTag *audio = (KSYFLVAudioTag *)tag;
                [buf putInt8:audio.packetType];  // AAC
            }
        }
        
        [buf appendData:tag.body];
        
        int previousTagSize = kFlvTagHeaderLength + bodySize + flagsSize;
        [buf putInt32:previousTagSize];
        
        [packet appendData:buf];
        if (debug) {
            NSLog(@"FLV TAG:\n%@", [buf hexString]);
        }
    }
}

- (void)reset {
    packet = [[NSMutableData alloc] init];
}

- (void)writeMetaTag:(KSYFLVMetadata *)aMetaTag {
    NSMutableData *buf = [[NSMutableData alloc] init];
    // First event name as a strig
    [buf putAMFString:@"onMetaData"];
    
    // Mixed array with size and string/type/data/ tuples
    [buf putInt8:kAMFDataTypeMixedArray];
    
    self.metaTag = aMetaTag;
    
    int metadataCount = (metaTag.videoCodecId >= 0 ? 5 : 0) +
    (metaTag.audioCodecId >= 0 ? 5 : 0) +
    3; // +3 for duration, file size and encoder name
    [buf putInt32:metadataCount];
    [buf putParam:@"duration" d:0];
    
    // Video encoding information
    if (metaTag.videoCodecId >= 0) {
        [buf putParam:@"width" d:metaTag.width];
        [buf putParam:@"height" d:metaTag.height ];
        [buf putParam:@"videodatarate" d:metaTag.videoBitrate];
        [buf putParam:@"framerate" d:metaTag.framerate];
        [buf putParam:@"videocodecid" d:metaTag.videoCodecId];
    }
    
    // Audio encoding information
    if (metaTag.audioCodecId >= 0) {
        [buf putParam:@"audiodatarate" d:metaTag.audioBitrate];
        [buf putParam:@"audiosamplerate" d:metaTag.sampleRate];
        [buf putParam:@"audiosamplesize" d:metaTag.sampleSize];
        [buf putParam:@"stereo" b:metaTag.stereo];
        [buf putParam:@"audiocodecid" d:metaTag.audioCodecId];
    }
    
    // FLV encoder information
    [buf putParam:@"encoder" str:@"ifFLVEncoder"];
    
    // File size
    [buf putParam:@"filesize" d:0];
    
    [buf putInt8:0];
    [buf putInt8:0];
    [buf putInt8:0];
    [buf putInt32:kAMFDataTypeObjectEnd];
    
    KSYFLVTag *tag = [[KSYFLVTag alloc] init];
    tag.dataType = kFLVTagTypeMeta;
    tag.timestamp = 0;
    tag.previuosTagSize = 0;
    tag.body = buf;
    tag.bodySize = [buf length];
    tag.bitflags = 0;
    
    [self writeTag:tag];
}

- (void)writeVideoPacket:(NSData *)data
               timestamp:(unsigned long)timestamp
                keyFrame:(BOOL)keyFrame
     compositeTimeOffset:(int)compositeTimeOffset {
    KSYFLVVideoTag *tag = [[KSYFLVVideoTag alloc] init];
    tag.timestamp = timestamp;
    tag.previuosTagSize = previousTagSize_;
    tag.body = data;
    tag.bodySize = [data length];
    tag.cts = 0;
    
    // If frame type is seekable we need to modify frame type in video tag.
    if (((Byte)(*((char *)[data bytes] + 4))) == 0x06 || keyFrame) {
        tag.frameType = FLV_FRAME_KEY;
        tag.cts = compositeTimeOffset;
    }
    
    tag.bitflags = 0;
    [self writeTag:tag];
}

- (void)writeAudioPacket:(NSData *)data timestamp:(unsigned long)timestamp {
    KSYFLVAudioTag *tag = [[KSYFLVAudioTag alloc] init];
    tag.timestamp = timestamp;
    tag.previuosTagSize = previousTagSize_;
    tag.body = data;
    tag.bodySize = [data length];
    tag.bitflags = 0;
    [self writeTag:tag];
}

- (void)writeAudioDecoderConfRecord:(NSData *)decoderBytes {
    KSYFLVAudioTag *tag = [[KSYFLVAudioTag alloc] init];
    tag.timestamp = 0;
    tag.previuosTagSize = 0;
    tag.body = decoderBytes;
    tag.bodySize = [decoderBytes length];
    tag.bitflags = 0;
    tag.packetType = kAACSequenceHeader;
    [self writeTag:tag];
}

- (void)writeVideoDecoderConfRecord:(NSData *)decoderBytes {
    KSYFLVVideoTag *tag = [[KSYFLVVideoTag alloc] init];
    tag.timestamp = 0;
    tag.previuosTagSize = 0;
    tag.body = decoderBytes;
    tag.bodySize = [decoderBytes length];
    tag.packetType = kAVCSequenceHeader;
    tag.frameType = FLV_FRAME_KEY;
    tag.bitflags = 0;
    [self writeTag:tag];
}

@end
