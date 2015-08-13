//
//  KSYFLVVideoTag.h
//  protos
//
//  Created by Blues on 10/18/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSYFLVTag.h"

@interface KSYFLVVideoTag : KSYFLVTag

@property (atomic, assign) int frameType;
@property (atomic, assign) int codecId;
@property (atomic, assign) int packetType;
@property (atomic, retain) NSData *body;
@property (atomic, assign) int cts;

@end
