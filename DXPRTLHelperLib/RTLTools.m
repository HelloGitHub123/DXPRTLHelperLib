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

#pragma mark - Helper Methods (Private)

/// 判断字符是否为 RTL 字符
/// 支持: 阿拉伯文, 希伯来文, 叙利亚文, 标记符号, N'Ko 等
+ (BOOL)isRTLCharacter:(unichar)c {
    // 阿拉伯文: U+0600-U+06FF
    if (c >= 0x0600 && c <= 0x06FF) {
        return YES;
    }

    // 希伯来文: U+0590-U+05FF
    if (c >= 0x0590 && c <= 0x05FF) {
        return YES;
    }

    // 叙利亚文: U+0700-U+074F
    if (c >= 0x0700 && c <= 0x074F) {
        return YES;
    }

    // 标记符号 (Thaana): U+0780-U+07BF
    if (c >= 0x0780 && c <= 0x07BF) {
        return YES;
    }

    // N'Ko: U+07C0-U+07FF
    if (c >= 0x07C0 && c <= 0x07FF) {
        return YES;
    }

    // Samaritan: U+0800-U+083F
    if (c >= 0x0800 && c <= 0x083F) {
        return YES;
    }

    // Mandaic: U+0840-U+085F
    if (c >= 0x0840 && c <= 0x085F) {
        return YES;
    }

    return NO;
}

/// 判断字符是否为 LTR 字符（英文或数字）
+ (BOOL)isLTRCharacter:(unichar)c {
    // 英文大写: U+0041-U+005A (A-Z)
    if (c >= 0x0041 && c <= 0x005A) {
        return YES;
    }

    // 英文小写: U+0061-U+007A (a-z)
    if (c >= 0x0061 && c <= 0x007A) {
        return YES;
    }

    return NO;
}

#pragma mark - Text Direction Detection

+ (BOOL)isStartingWithRTL:(NSString *)text {
    if (!text || text.length == 0) {
        return NO;
    }

    // 遍历字符串，找到第一个有方向属性的字符
    for (NSInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];

        // 检查是否为 RTL 字符
        if ([self isRTLCharacter:c]) {
            return YES;
        }

        // 检查是否为 LTR 字符
        if ([self isLTRCharacter:c]) {
            return NO;
        }
    }

    return NO;
}

+ (BOOL)isStartingWithLTR:(NSString *)text {
    if (!text || text.length == 0) {
        return NO;
    }

    // 遍历字符串，找到第一个有方向属性的字符
    for (NSInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];

        // 检查是否为 LTR 字符
        if ([self isLTRCharacter:c]) {
            return YES;
        }

        // 检查是否为 RTL 字符
        if ([self isRTLCharacter:c]) {
            return NO;
        }
    }

    return NO;
}

+ (BOOL)isAllRTL:(NSString *)text {
    if (!text || text.length == 0) {
        return NO;
    }

    BOOL hasRTLCharacter = NO;

    // 检查所有字符是否都是 RTL 或中性字符
    for (NSInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];

        // 如果遇到 LTR 字符，则不是全部 RTL
        if ([self isLTRCharacter:c]) {
            return NO;
        }

        // 检查是否为 RTL 字符
        if ([self isRTLCharacter:c]) {
            hasRTLCharacter = YES;
        }
        // 允许数字、空格、标点等中性字符
    }

    return hasRTLCharacter;
}

+ (BOOL)isAllLTR:(NSString *)text {
    if (!text || text.length == 0) {
        return NO;
    }

    BOOL hasLTRCharacter = NO;

    // 检查所有字符是否都是 LTR 或中性字符
    for (NSInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];

        // 如果遇到 RTL 字符，则不是全部 LTR
        if ([self isRTLCharacter:c]) {
            return NO;
        }

        // 检查是否为 LTR 字符
        if ([self isLTRCharacter:c]) {
            hasLTRCharacter = YES;
        }
        // 允许数字、空格、标点等中性字符
    }

    return hasLTRCharacter;
}

@end
