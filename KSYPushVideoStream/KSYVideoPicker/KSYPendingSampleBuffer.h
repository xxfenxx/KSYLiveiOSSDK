//
//  KSYPendingSampleBuffer.h
//  KSYVideoPicker
//
//  Created by Blues on 12/10/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSYAVAssetEncoder.h"

@interface KSYPendingSampleBuffer : NSObject

+ (KSYPendingSampleBuffer *)pendingSampleBuffer:(CMSampleBufferRef)sampleBuffer
                                        ofType:(IFCapturedBufferType)mediaType;

- (CMSampleBufferRef)getSampleBuffer;

@property (atomic, assign) IFCapturedBufferType mediaType;

@end
