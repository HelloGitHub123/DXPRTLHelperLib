//
//  UIPageControl+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/4.
//

#import "UIPageControl+RTL.h"
#import "RTLTools.h"

@implementation UIPageControl (RTL)


+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithFrame:) swizzledSEL:@selector(initRTLWithFrame:) isInstanceMethod:YES];
    });
}

- (instancetype)initRTLWithFrame:(CGRect)frame
{
    self = [self initRTLWithFrame:frame];
    if (self) {
        if (@available(iOS 16.0, *)) {
            self.direction = UIPageControlDirectionNatural;
        } else {
                
        }
    }
    return self;
}

@end
