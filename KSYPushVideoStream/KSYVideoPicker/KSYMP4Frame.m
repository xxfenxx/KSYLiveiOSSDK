//
//  KSYMP4Frame.m
//  protos
//
//  Created by Blues on 10/12/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import "KSYMP4Frame.h"

@implementation KSYMP4Frame

@synthesize size;
@synthesize offset;
@synthesize timestamp;
@synthesize type;
@synthesize keyFrame;
@synthesize timeOffset;

- (NSComparisonResult)compareMP4Frame:(KSYMP4Frame *)otherObject {
    if (timestamp > otherObject.timestamp) {
        return 1;
    } else if (timestamp < otherObject.timestamp) {
        return -1;
    } else if (timestamp == otherObject.timestamp && offset > otherObject.offset) {
        return 1;
    } else if (timestamp == otherObject.timestamp && offset < otherObject.offset) {
        return -1;
    }
    
    return 0;
}

@end
