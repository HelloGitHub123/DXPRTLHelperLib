//
//  UINavigationController+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/1.
//

#import "UINavigationController+RTL.h"
#import "RTLTools.h"

@implementation UINavigationController (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(init) swizzledSEL:@selector(initRTL) isInstanceMethod:YES];
    });
}

- (instancetype)initRTL {
    self = [self initRTL];
    if (self) {
        self.view.semanticContentAttribute = [RTLTools currentLanSemanticStyle];
    }
    return self;
}


@end
