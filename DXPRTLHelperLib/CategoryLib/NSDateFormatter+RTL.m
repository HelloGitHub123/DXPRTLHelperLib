//
//  NSDateFormatter+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/11.
//

#import "NSDateFormatter+RTL.h"
#import "RTLTools.h"

@implementation NSDateFormatter (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(init) swizzledSEL:@selector(initRTL) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setLocale:) swizzledSEL:@selector(RTLSetLocale:) isInstanceMethod:YES];
    });
}

- (void)RTLSetLocale:(NSLocale *)locale {
    if ([RTLTools canDoRTLWork]) {
        locale = [[NSLocale alloc]initWithLocaleIdentifier:[RTLTools getLocale]];
    } else {
        
    }
    [self RTLSetLocale:locale];
}

- (instancetype)initRTL
{
    self = [self initRTL];
    if (self) {
        if ([RTLTools canDoRTLWork]) {
            NSLocale *locale = [[NSLocale alloc]initWithLocaleIdentifier:[RTLTools getLocale]];
            [self RTLSetLocale:locale];
        } else {
            
        }
    }
    return self;
}

@end
