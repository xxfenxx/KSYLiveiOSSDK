//
//  KSYFLVHeader.h
//  protos
//
//  Created by Blues on 10/10/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSYFLVHeader : NSObject

@property (atomic, assign) BOOL flagAudio;
@property (atomic, assign) BOOL flagVideo;
@property (atomic, assign) Byte version;

- (NSData *)write;
- (NSString *)toString;

@end
