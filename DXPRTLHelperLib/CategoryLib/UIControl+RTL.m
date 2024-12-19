//
//  UIControl+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/7.
//

#import "UIControl+RTL.h"
#import "RTLTools.h"

@implementation UIControl (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setContentHorizontalAlignment:) swizzledSEL:@selector(RTLSetContentHorizontalAlignment:) isInstanceMethod:YES];
    });
}

- (void)RTLSetContentHorizontalAlignment:(UIControlContentHorizontalAlignment)contentHorizontalAlignment {
    if ([RTLTools canDoRTLWork]) {
        switch (contentHorizontalAlignment) {
            case UIControlContentHorizontalAlignmentLeft:
                contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;
                break;
            case UIControlContentHorizontalAlignmentRight:
                contentHorizontalAlignment = UIControlContentHorizontalAlignmentTrailing;
                break;
            default:
                break;
        }
    }
    [self RTLSetContentHorizontalAlignment:contentHorizontalAlignment];
}

@end
