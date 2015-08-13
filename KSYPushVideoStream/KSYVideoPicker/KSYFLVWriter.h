//
//  KSYFLVWriter.h
//  protos
//
//  Created by Blues on 10/10/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSYFLVMetadata;
@class KSYFLVTag;

@interface KSYFLVWriter : NSObject

@property (atomic, readonly) NSMutableData *packet;
@property (atomic, assign) BOOL debug;

- (void)writeHeader;
- (void)writeTag:(KSYFLVTag *)tag;
- (void)writeMetaTag:(KSYFLVMetadata *)metaTag;
- (void)writeVideoPacket:(NSData *)data timestamp:(unsigned long)timestamp
                keyFrame:(BOOL)keyFrame
     compositeTimeOffset:(int)compositeTimeOffset;
- (void)writeAudioPacket:(NSData *)data timestamp:(unsigned long)timestamp;
- (void)writeAudioDecoderConfRecord:(NSData *)decoderBytes;
- (void)writeVideoDecoderConfRecord:(NSData *)decoderBytes;
- (void)reset;

@end
