//
//  NSData+Hex.h
//  NSData+HexDemo
//
//  Created by Blues on 10/3/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Hex)

- (NSString *)hexString;

- (NSString *)hexString:(NSUInteger)size;

@end