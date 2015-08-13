//
//  KSYBytesData.h
//  ffmpeg-wrapper
//
//  Created by Blues on 10/18/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSYBytesData : NSObject

+ (KSYBytesData *)dataWithNSData:(NSData *)data;

- (int8_t)getInt8;
- (int16_t)getInt16;
- (int32_t)getInt32;
- (int64_t)getInt64;
- (NSData *)getBytes:(NSUInteger)size;
- (NSString *)getString:(NSUInteger)size;
- (void)skip:(int)pos;
- (void)reset;
- (const void *)bytes;
- (NSUInteger)length;

@property (atomic, readonly) NSUInteger position;

@end
