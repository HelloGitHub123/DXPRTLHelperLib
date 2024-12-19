//
//  UIButton+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/5.
//

#import "UIButton+RTL.h"
#import "RTLTools.h"

@implementation UIButton (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setContentEdgeInsets:) swizzledSEL:@selector(RTLSetContentEdgeInsets:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setImageEdgeInsets:) swizzledSEL:@selector(RTLSetImageEdgeInsets:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setTitleEdgeInsets:) swizzledSEL:@selector(RTLSetTitleEdgeInsets:) isInstanceMethod:YES];
    });
}

- (void)RTLSetContentEdgeInsets:(UIEdgeInsets)contentEdgeInsets {
    if ([RTLTools canDoRTLWork]) {
        [self RTLSetContentEdgeInsets:[RTLTools RTLEdgeInsetsWithInsets:contentEdgeInsets]];
    } else {
        [self RTLSetContentEdgeInsets:contentEdgeInsets];
    }
}

- (void)RTLSetImageEdgeInsets:(UIEdgeInsets)imageEdgeInsets {
    if ([RTLTools canDoRTLWork]) {
        [self RTLSetImageEdgeInsets:[RTLTools RTLEdgeInsetsWithInsets:imageEdgeInsets]];
    } else {
        [self RTLSetImageEdgeInsets:imageEdgeInsets];
    }
}

- (void)RTLSetTitleEdgeInsets:(UIEdgeInsets)titleEdgeInsets {
    if ([RTLTools canDoRTLWork]) {
        [self RTLSetTitleEdgeInsets:[RTLTools RTLEdgeInsetsWithInsets:titleEdgeInsets]];
    } else {
        [self RTLSetTitleEdgeInsets:titleEdgeInsets];
    }
}

@end
