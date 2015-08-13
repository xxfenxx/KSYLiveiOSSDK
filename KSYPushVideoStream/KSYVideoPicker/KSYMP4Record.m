//
//  KSYMP4Record.m
//  protos
//
//  Created by Blues on 10/15/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import "KSYMP4Record.h"

/**
 @abstract
 KSYMP4Record
 */
@implementation KSYMP4Record

@synthesize firstChunk;
@synthesize sampleDescription;
@synthesize samplePerChunk;

@end

/**
 @abstract
 MP4TimeSampleRecord
 */
@implementation MP4TimeSampleRecord

@synthesize consecutiveSamples;
@synthesize sampleDuration;

@end

/**
 @abstract
 MP4CompositionTimeSampleRecord
 */
@implementation MP4CompositionTimeSampleRecord

@synthesize consecutiveSamples;
@synthesize sampleOffset;

@end