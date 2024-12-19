//
//  RTLTools.m
//  Base
//
//  Created by 胡灿 on 2024/11/4.
//

#import "RTLTools.h"
#import "RTLConfigurationManager.h"
#import <objc/runtime.h>

// 这里的工具方法只是设置rtl环境下的情况
// [self canDoRTLWork] 交给分类中去调用判断是否是rtl环境

@implementation RTLTools

+ (BOOL)canDoRTLWork {
    return [RTLConfigurationManager sharedInstance].enableRTLCategoryWork && [RTLConfigurationManager sharedInstance].currentLanSemanticStyle == UISemanticContentAttributeForceRightToLeft;
}

+ (void)methodSwizzlingWithClass:(Class)cls oriSEL:(SEL)oriSEL swizzledSEL:(SEL)swizzledSEL isInstanceMethod:(BOOL)isInstanceMethod {
    if (!cls) {
        NSLog(@"传入的交换类不能为空");
        return;
    }

    // 获取类中的方法
    Method oriMethod = nil;
    // 要被交换的方法
    Method swiMethod = nil;
    
    if (isInstanceMethod) {
        oriMethod = class_getInstanceMethod(cls, oriSEL);
        swiMethod = class_getInstanceMethod(cls, swizzledSEL);
    } else {
        oriMethod = class_getClassMethod(cls, oriSEL);
        swiMethod = class_getClassMethod(cls, swizzledSEL);
        if (oriMethod && swiMethod) {
            method_exchangeImplementations(oriMethod, swiMethod);
        }
        return;
    }

    // 判断类中是否存在该方法-避免动作没有意义
    if (!oriMethod) {

       // 在oriMethod为nil时，添加oriSEL的方法，实现为swiMethod
       class_addMethod(cls, oriSEL, method_getImplementation(swiMethod), method_getTypeEncoding(swiMethod));

       // 替换后将swizzledSEL复制一个不做任何事的空实现,代码如下:
       method_setImplementation(swiMethod, imp_implementationWithBlock(^(id self, SEL _cmd){

           NSLog(@"来了一个空的 imp");
       }));
    }

    // 一般交换方法: 交换自己有的方法 -- 走下面 因为自己有意味添加方法失败
    // 交换自己没有实现的方法:
    //   首先第一步:会先尝试给自己添加要交换的方法 :personInstanceMethod (SEL) -> swiMethod(IMP)
    //   然后再将父类的IMP给swizzle  personInstanceMethod(imp) -> swizzledSEL
    //oriSEL:personInstanceMethod

    // 向类中添加oriSEL方法，方法实现为swiMethod
    BOOL didAddOriMethod = class_addMethod(cls, oriSEL, method_getImplementation(swiMethod), method_getTypeEncoding(swiMethod));

    // 自己有意味添加方法失败-所以这里会是false
    if (didAddOriMethod) {
       // 如果添加成功，表示原本没有oriMethod方法，此时将swizzledSEL的方法实现，替换成oriMethod实现
       class_replaceMethod(cls, swizzledSEL, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    }else{
       // 方法交换
       method_exchangeImplementations(oriMethod, swiMethod);
    }
}

+ (UIEdgeInsets)RTLEdgeInsetsWithInsets:(UIEdgeInsets)insets {
    if (insets.left != insets.right) {
        CGFloat temp = insets.left;
        insets.left = insets.right;
        insets.right = temp;
    }
    return insets;
}

+ (UIRectCorner)RTLRectCornersWithCorners:(UIRectCorner)corners {
    if (corners == UIRectCornerAllCorners) {
        return corners;;
    }
    UIRectCorner rtlCorners = 0UL;
    if (corners & UIRectCornerTopLeft) {
        rtlCorners |= UIRectCornerTopRight;
    }
    if (corners & UIRectCornerTopRight) {
        rtlCorners |= UIRectCornerTopLeft;
    }
    if (corners & UIRectCornerBottomLeft) {
        rtlCorners |= UIRectCornerBottomRight;
    }
    if (corners & UIRectCornerBottomRight) {
        rtlCorners |= UIRectCornerBottomLeft;
    }
    return rtlCorners;
}

+ (BOOL)evaluateImgToReverse:(NSString *)imgName {
    if (!imgName) {
        return NO;
    }
    
    if ([[RTLConfigurationManager sharedInstance].keepOriginImgs containsObject:imgName]) {
        return NO;
    } else if ([[RTLConfigurationManager sharedInstance].needReverseImgs containsObject:imgName]) {
        return YES;
    } else {
        for (NSString *regular in [RTLConfigurationManager sharedInstance].needReverseImgWithRegulars) {
            if (regular && ![regular isEqualToString:@""]) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@", regular]];
                @try {
                    // 会报错
                    if ([predicate evaluateWithObject:imgName]) {
                        return YES;
                    }
                } @catch (NSException *exception) {
                    NSLog(@"%@ is not a valid regular expression!", regular);
                } @finally {
                    
                }
            }
        }
    }
    return NO;
}

+ (BOOL)isZeroRect:(CGRect)frame {
    return frame.origin.x == 0 && frame.origin.y == 0 && frame.size.width == 0 && frame.size.height == 0;
}

+ (CGRect)getFrame:(CGRect)frame withSuperBounds:(CGRect)superBounds {
    if (![self isZeroRect:frame] && ![self isZeroRect:superBounds]) {
        CGFloat x = superBounds.size.width - frame.size.width - frame.origin.x;
        return CGRectMake(x, frame.origin.y, frame.size.width, frame.size.height);
    } else {
        return frame;
    }
}

+ (CGRect)getFrame:(CGRect)frame withView:(UIView *)view {
    if (!view) return CGRectZero;
    if (![self isZeroRect:frame] && view.superview) {
        if (![view.superview isKindOfClass:[UIScrollView class]] && ![self isZeroRect:view.superview.frame]) {
            CGFloat x = view.superview.bounds.size.width - frame.size.width - frame.origin.x;
            return CGRectMake(x, frame.origin.y, frame.size.width, frame.size.height);
        } else if ([view.superview isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)view.superview;
            if (scrollView.contentSize.width != 0 && scrollView.contentSize.height != 0) {
                CGFloat x = 2 * scrollView.contentInset.left + scrollView.contentSize.width - frame.size.width - frame.origin.x;
                return CGRectMake(x, frame.origin.y, frame.size.width, frame.size.height);
            }
        }
        
    }
    return frame;
}

+ (BOOL)isAtomView:(UIView *)view {
    for (Class atomViewClass in [RTLConfigurationManager sharedInstance].atomViewClasses) {
        if ([view isKindOfClass:atomViewClass]) {
            return YES;
        }
    }
    return NO;
}

+ (UISemanticContentAttribute)currentLanSemanticStyle {
    return [RTLConfigurationManager sharedInstance].currentLanSemanticStyle;
}

+ (void)setEnableRTLCategoryWork:(BOOL)enabled {
    [RTLConfigurationManager sharedInstance].enableRTLCategoryWork = enabled;
}

+ (NSString *)getLocale {
    return [RTLConfigurationManager sharedInstance].locale;
}

@end
