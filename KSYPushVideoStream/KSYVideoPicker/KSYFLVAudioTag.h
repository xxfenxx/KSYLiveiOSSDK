//
//  KSYFLVAudioTag.h
//  protos
//
//  Created by Blues on 10/18/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSYFLVTag.h"

@interface KSYFLVAudioTag : KSYFLVTag

@property (atomic, assign) int soundFormat;
@property (atomic, assign) int soundRate;
@property (atomic, assign) int soundSize;
@property (atomic, assign) int packetType;
@property (atomic, assign) int soundType;
@property (atomic, retain) NSData *body;

@end
