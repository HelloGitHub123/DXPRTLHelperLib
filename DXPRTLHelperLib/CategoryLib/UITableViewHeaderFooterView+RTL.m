//
//  UITableViewHeaderFooterView+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/1.
//

#import "UITableViewHeaderFooterView+RTL.h"
#import "RTLTools.h"

@implementation UITableViewHeaderFooterView (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithReuseIdentifier:) swizzledSEL:@selector(initRTLWithReuseIdentifier:) isInstanceMethod:YES];
    });
}

- (instancetype)initRTLWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [self initRTLWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.semanticContentAttribute = [RTLTools currentLanSemanticStyle];
    }
    return self;
}

@end
