//
//  KSYPendingSampleBuffer.m
//  KSYVideoPicker
//
//  Created by Blues on 12/10/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import "KSYPendingSampleBuffer.h"

@interface KSYPendingSampleBuffer () {
    CMSampleBufferRef sampleBuffer_;
    IFCapturedBufferType mediaType_;
}

@end

@implementation KSYPendingSampleBuffer

@synthesize mediaType;

+ (KSYPendingSampleBuffer *)pendingSampleBuffer:(CMSampleBufferRef)sampleBuffer
                                         ofType:(IFCapturedBufferType)mediaType {
    
    
    return [[KSYPendingSampleBuffer alloc] initWithSampleBuffer:sampleBuffer
                                                        andType:mediaType];
}

- (id)initWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
                   andType:(IFCapturedBufferType)aMediaType {
    self = [super init];
    if (self) {
        CFRetain(sampleBuffer);
        sampleBuffer_ = sampleBuffer;
        self.mediaType = aMediaType;
    }
    return self;
}

- (CMSampleBufferRef)getSampleBuffer {
    return sampleBuffer_;
}

- (void)dealloc {
    CFRelease(sampleBuffer_);
    NSLog(@"dealloc??");
}

@end
