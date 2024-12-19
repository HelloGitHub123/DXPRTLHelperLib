//
//  UIScrollView+RTL.m
//  AccountManagement
//
//  Created by 胡灿 on 2024/10/31.
//

#import "UIScrollView+RTL.h"
#import "RTLTools.h"

@implementation UIScrollView (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setContentSize:) swizzledSEL:@selector(RTLSetContentSize:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setContentInset:) swizzledSEL:@selector(RTLSetContentInset:) isInstanceMethod:YES];
    });
}

- (void)RTLSetContentSize:(CGSize)size {
    CGSize newSize = size;
    CGSize oldSize = self.contentSize;
    BOOL hasChanged = newSize.width != oldSize.width || newSize.height != oldSize.height;
    [self RTLSetContentSize:size];
    if (size.width > 0 && ![self isKindOfClass:[UICollectionView class]] && ![self isKindOfClass:[UITableView class]] && hasChanged && [RTLTools canDoRTLWork]) {
//        NSLog(@"content size is (%f, %f)", size.width, size.height);
        [self setContentOffset:CGPointMake(self.contentInset.left + self.contentSize.width-self.frame.size.width, self.contentOffset.y) animated:NO];
        if (self.contentInset.left + size.width-self.frame.size.width < 0) {
            self.contentInset = UIEdgeInsetsMake(self.contentInset.top, self.contentInset.left, self.contentInset.bottom, self.frame.size.width - size.width);
//            self.scrollEnabled = false;
        }
    } else {
        
    }
}

- (void)RTLSetContentInset:(UIEdgeInsets)contentInset {
    if ([RTLTools canDoRTLWork]) {
        [self RTLSetContentInset:[RTLTools RTLEdgeInsetsWithInsets:contentInset]];
    } else {
        [self RTLSetContentInset:contentInset];
    }
}

@end
