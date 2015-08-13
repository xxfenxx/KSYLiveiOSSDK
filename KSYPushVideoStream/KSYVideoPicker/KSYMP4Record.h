//
//  KSYMP4Record.h
//  protos
//
//  Created by Blues on 10/15/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 @abstract
  KSYMP4Record
 */
@interface KSYMP4Record : NSObject

@property (atomic, assign) int firstChunk;
@property (atomic, assign) int samplePerChunk;
@property (atomic, assign) int sampleDescription;

@end

/**
 @abstract
  MP4TimeSampleRecord
 */
@interface MP4TimeSampleRecord : NSObject

@property (atomic, assign) int consecutiveSamples;
@property (atomic, assign) int sampleDuration;

@end

/**
 @abstract
  MP4CompositionTimeSampleRecord
 */
@interface MP4CompositionTimeSampleRecord : NSObject

@property (atomic, assign) int consecutiveSamples;
@property (atomic, assign) int sampleOffset;

@end