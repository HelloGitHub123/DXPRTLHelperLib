//
//  RTLHelper.m
//  FDFullScreenPopGestureDemo
//
//  Created by cs on 2018/10/20.
//  Copyright © 2018 cs. All rights reserved.
//

#import "RTLHelper.h"
#import "RTLConfigurationManager.h"
#import "UIView+RTLHandLayout.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "RTLDirectionMarks.h"

@implementation RTLHelper

+ (instancetype)sharedInstance {
    static RTLHelper *helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[RTLHelper alloc]initRTL];
    });
    return helper;
}

- (instancetype)initRTL {
    self = [super init];
    if (self) {
        // todo
    }
    return self;
}

- (void)doRTLBlock:(RTLBlock)rtlBlock enableCategoryWork:(BOOL)enableCategoryWork {
    if (rtlBlock) {
        if (enableCategoryWork) {
            rtlBlock([self isLanguageRTL]);
        } else {
            [RTLConfigurationManager sharedInstance].enableRTLCategoryWork = NO;
            rtlBlock([self isLanguageRTL]);
            [RTLConfigurationManager sharedInstance].enableRTLCategoryWork = YES;
        }
    }
}

- (void)doRTLBlock:(RTLBlock)rtlBlock {
    [self doRTLBlock:rtlBlock enableCategoryWork:YES];
}

- (UIImage *)reverseImgFilterWithUrl:(NSString * _Nullable)url image:(UIImage *)image {
    if ([self isLanguageRTL] && [self evaluateImgToReverse:url] && image) {
        // 反转图片
        image = [UIImage imageWithCGImage:image.CGImage
                                    scale:image.scale
                                 orientation:UIImageOrientationUpMirrored];
    }
    return image;
}

- (UIImage *)reverseImgWithImage:(UIImage *)image {
    if (image && [self isLanguageRTL]) {
        // 反转图片
        image = [UIImage imageWithCGImage:image.CGImage
                                    scale:image.scale
                                 orientation:UIImageOrientationUpMirrored];
    }
    return image;
}

- (BOOL)isAtomView:(UIView *)view {
    for (Class atomViewClass in [RTLConfigurationManager sharedInstance].atomViewClasses) {
        if ([view isKindOfClass:atomViewClass]) {
            return YES;
        }
    }
    return NO;
}

- (void)setFrame:(CGRect)frame withView:(UIView *)view {
    [self setFrame:frame withView:view enableSubviews:NO];
}

- (void)setFrame:(CGRect)frame withView:(UIView *)view enableSubviews:(BOOL)enableSubviews {
    if (!view) return;
    if (view.superview && [self isLanguageRTL]) {
//        CGFloat x = view.superview.bounds.size.width - frame.size.width - frame.origin.x;
//        view.frame = CGRectMake(x, frame.origin.y, frame.size.width, frame.size.height);
        if (![view.superview isKindOfClass:[UIScrollView class]]) {
            CGFloat x = view.superview.bounds.size.width - frame.size.width - frame.origin.x;
            view.frame = CGRectMake(x, frame.origin.y, frame.size.width, frame.size.height);
        } else if ([view.superview isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)view.superview;
            if (scrollView.contentSize.width != 0 && scrollView.contentSize.height != 0) {
                CGFloat x = 2 * scrollView.contentInset.left + scrollView.contentSize.width - frame.size.width - frame.origin.x;
                view.frame = CGRectMake(x, frame.origin.y, frame.size.width, frame.size.height);
            }
        }
        if (enableSubviews && ![self isAtomView:view]) {
            for (UIView *subview in view.subviews) {
                [self setFrame:subview.frame withView:subview enableSubviews:YES];
            }
        }
    } else {
        view.frame = frame;
    }
}

- (void)setFrame:(CGRect)frame withLayer:(CALayer *)layer {
    [self setFrame:frame withLayer:layer enableSublayers:NO];
}

- (void)setFrame:(CGRect)frame withLayer:(CALayer *)layer enableSublayers:(BOOL)enableSublayers {
    if (!layer) return;
    if (layer.superlayer && [self isLanguageRTL]) {
        CGFloat x = layer.superlayer.bounds.size.width - frame.size.width - frame.origin.x;
        layer.frame = CGRectMake(x, frame.origin.y, frame.size.width, frame.size.height);
        if (enableSublayers) {
            for (CALayer *sublayer in layer.sublayers) {
                [self setFrame:sublayer.frame withLayer:sublayer];
            }
        }
    } else {
        layer.frame = frame;
    }
}

- (void)enableHandLayoutClassWithToken:(NSString *)clsToken {
    Class cls = NSClassFromString(clsToken);
    if (([cls isKindOfClass:object_getClass([UIView class])]) || [cls isKindOfClass:object_getClass([UIViewController class])]) {
        if ([cls rtl_layoutStyle] == RTLLayoutStyleUnset) [cls setRtl_layoutStyle:RTLLayoutStyleHand];  // 不知为啥，直接cls.rtl_layoutStyle报错
    }
}

- (void)enableHandLayoutClassWithTokens:(NSArray<NSString *> *)clsTokens {
    for (NSString *clsToken in clsTokens) {
        [self enableHandLayoutClassWithToken:clsToken];
    }
}

#pragma mark -- getter

- (UISemanticContentAttribute)currentLanSemanticStyle {
    return [RTLConfigurationManager sharedInstance].currentLanSemanticStyle;
}

- (NSMutableSet<NSString *> *)needReverseImgs {
    return [RTLConfigurationManager sharedInstance].needReverseImgs;
}

- (NSMutableSet<NSString *> *)needReverseImgWithRegulars {
    return [RTLConfigurationManager sharedInstance].needReverseImgWithRegulars;
}

- (NSMutableSet<NSString *> *)keepOriginImgs {
    return [RTLConfigurationManager sharedInstance].keepOriginImgs;
}

- (NSString *)locale {
    return [RTLConfigurationManager sharedInstance].locale;
}


#pragma mark -- setter

- (void)setCurrentLanSemanticStyle:(UISemanticContentAttribute)currentLanSemanticStyle {
    [RTLConfigurationManager sharedInstance].currentLanSemanticStyle = currentLanSemanticStyle;
}

- (void)setLocale:(NSString *)locale {
    [RTLConfigurationManager sharedInstance].locale = locale;
}

#pragma mark -- tools func

- (BOOL)isLanguageRTL {
    return [RTLConfigurationManager sharedInstance].currentLanSemanticStyle == UISemanticContentAttributeForceRightToLeft;
}

- (BOOL)evaluateImgToReverse:(NSString *)imgName {
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

// 防止文本第一个字符不是从右往左的语言而导致误判
- (NSString *)RTLString:(NSString *)string {
    if (!string || [string isEqualToString:@""] || string.length == 0) {
        return @"";
    }
    // 正则表达式匹配从右到左的语言文本方向的字符
    NSString *rtlLanRegualr = @"\\u0590-\\u05FF\\u0600-\\u06FF\\u0700-\\u074F\\u0750-\\u077F\\u08A0-\\u08FF\\uFB1D-\\uFB4F\\uFE50-\\uFE6F\\uFB50-\\uFDFF\\uFE70-\\uFEFF\\u0780-\\u07BF\\u0E80-\\u0EFF\\u1000-\\u137F\\u13A0-\\u13FF\\u1780-\\u17FF\\u1800-\\u18AF\\u200F-\\u202E";  // 从右往左阅读的语言unicode范围

    // 匹配LTR文本块（非RTL字符序列）
    // 只在LTR部分前后添加ltrStartMark和ltrEndMark，RTL部分保持不变
    NSString *ltrPattern = [NSString stringWithFormat:@"[^%@]+", rtlLanRegualr];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:ltrPattern options:0 error:nil];
    NSArray *ltrResultArr = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];

    NSMutableString *newString = [string mutableCopy];

    // 从后往前替换，避免位置变化影响
    for (NSTextCheckingResult *ltrResult in [ltrResultArr reverseObjectEnumerator]) {
        NSString *ltrStr = [string substringWithRange:ltrResult.range];
        NSString *newLtrStr = RTL_WRAP_LTR(ltrStr);
        [newString replaceCharactersInRange:ltrResult.range withString:newLtrStr];
    }

    string = [newString copy];

    if ([self isLanguageRTL]) {
        string = RTL_WRAP_RTL(string);
    } else {
        string = RTL_WRAP_LTR(string);
    }

    return string;
}

- (NSString *)removeDirectionMask:(NSString *)string {
    if (!string) {
        return @"";
    }
    // 移除所有 Unicode 双向文本控制字符
    // \u200E LRM (Left-to-Right Mark)
    // \u200F RLM (Right-to-Left Mark)
    // \u202A LRE (Left-to-Right Embedding)
    // \u202B RLE (Right-to-Left Embedding)
    // \u202C PDF (Pop Directional Formatting)
    // \u202D LRO (Left-to-Right Override)
    // \u202E RLO (Right-to-Left Override)
    // \u2066 LRI (Left-to-Right Isolate)
    // \u2067 RLI (Right-to-Left Isolate)
    // \u2068 FSI (First Strong Isolate)
    // \u2069 PDI (Pop Directional Isolate)
    NSMutableString *result = [string mutableCopy];
    NSString *pattern = @"[\\u200E\\u200F\\u202A\\u202B\\u202C\\u202D\\u202E\\u2066\\u2067\\u2068\\u2069]";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    [regex replaceMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:@""];
    return [result copy];
}

/// 处理 NSAttributedString 的 RTL 适配，保留各部分的属性配置
///
/// 与RTLString方法功能相同，但专门处理NSAttributedString，保留原有的字体、颜色等属性
/// 对LTR文本块前后添加方向标记，RTL文本保持不变
/// - Parameter attributedString: 要适配RTL的NSAttributedString
- (NSAttributedString *)RTLAttributedString:(NSAttributedString *)attributedString {
    if (!attributedString || attributedString.length == 0) {
        return attributedString;
    }

    NSString *string = attributedString.string;
    NSString *rtlLanRegualr = @"\\u0590-\\u05FF\\u0600-\\u06FF\\u0700-\\u074F\\u0750-\\u077F\\u08A0-\\u08FF\\uFB1D-\\uFB4F\\uFE50-\\uFE6F\\uFB50-\\uFDFF\\uFE70-\\uFEFF\\u0780-\\u07BF\\u0E80-\\u0EFF\\u1000-\\u137F\\u13A0-\\u13FF\\u1780-\\u17FF\\u1800-\\u18AF\\u200F-\\u202E";

    // 匹配LTR文本块（非RTL字符序列）
    NSString *ltrPattern = [NSString stringWithFormat:@"[^%@]+", rtlLanRegualr];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:ltrPattern options:0 error:nil];
    NSArray *ltrResultArr = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];

    NSMutableAttributedString *newAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];

    // 从后往前插入，避免位置变化影响
    for (NSTextCheckingResult *ltrResult in [ltrResultArr reverseObjectEnumerator]) {
        NSRange ltrRange = ltrResult.range;

        // 获取LTR块末尾字符的属性，用于endMark
        NSDictionary *endAttributes = nil;
        if (ltrRange.location + ltrRange.length > 0 && ltrRange.location + ltrRange.length <= newAttrString.length) {
            endAttributes = [newAttrString attributesAtIndex:(ltrRange.location + ltrRange.length - 1) effectiveRange:NULL];
        }

        // 在结束位置插入ltrEndMark
        NSAttributedString *endMark = [[NSAttributedString alloc] initWithString:RTLPopDirectionalIsolate attributes:endAttributes];
        [newAttrString insertAttributedString:endMark atIndex:(ltrRange.location + ltrRange.length)];

        // 获取LTR块开始字符的属性，用于startMark
        NSDictionary *startAttributes = nil;
        if (ltrRange.location < newAttrString.length) {
            startAttributes = [newAttrString attributesAtIndex:ltrRange.location effectiveRange:NULL];
        }

        // 在开始位置插入ltrStartMark
        NSAttributedString *startMark = [[NSAttributedString alloc] initWithString:RTLLEFTToRIGHTIsolate attributes:startAttributes];
        [newAttrString insertAttributedString:startMark atIndex:ltrRange.location];
    }

    NSString *resultString = newAttrString.string;

    // 添加整体的方向标记
    NSMutableAttributedString *finalString = [[NSMutableAttributedString alloc] initWithAttributedString:newAttrString];
    if ([self isLanguageRTL]) {
        NSAttributedString *rtlMark = [[NSAttributedString alloc] initWithString:RTLRIGHTToLEFTIsolate];
        [finalString insertAttributedString:rtlMark atIndex:0];
        NSAttributedString *rtlEndMark = [[NSAttributedString alloc] initWithString:RTLPopDirectionalIsolate];
        [finalString appendAttributedString:rtlEndMark];
    } else {
        NSAttributedString *ltrMark = [[NSAttributedString alloc] initWithString:RTLLEFTToRIGHTIsolate];
        [finalString insertAttributedString:ltrMark atIndex:0];
        NSAttributedString *rtlEndMark = [[NSAttributedString alloc] initWithString:RTLPopDirectionalIsolate];
        [finalString appendAttributedString:rtlEndMark];
    }

    return finalString;
}

/**
@brief 替换类的类方法
@param cls 要修改的类
@param originalSelector 要替换的方法
@param swizzledSelector 新的方法实现
*/
- (void)swizzleClassMethodWithCls:(Class)cls oriSel:(SEL)originalSelector swiSel:(SEL)swizzledSelector {
    if (!cls) {
        NSLog(@"交换方法失败--请保证交换的类名不为空");
        return;
    }
    
    if (!originalSelector || !swizzledSelector) {
        NSLog(@"交换方法失败--请保证交换的方法名不为空");
        return;
    }
    
    Class originalMetaCls = object_getClass(cls);
    Class swizzledMetaCls = object_getClass(cls);
    
    Method originalMethod = class_getClassMethod(originalMetaCls, originalSelector);
    Method swizzledMethod = class_getClassMethod(swizzledMetaCls, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(originalMetaCls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(originalMetaCls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
}

/**
@brief 替换类的对象方法
@param cls 要修改的类
@param originalSelector 要替换的方法
@param swizzledSelector 新的方法实现
*/
- (void)swizzleInstanceMethodWithCls:(Class)cls oriSel:(SEL)originalSelector swiSel:(SEL)swizzledSelector {
    if (!cls) {
        NSLog(@"交换方法失败--请保证交换的类名不为空");
        return;
    }
    
    if (!originalSelector || !swizzledSelector) {
        NSLog(@"交换方法失败--请保证交换的方法名不为空");
        return;
    }
    
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(cls,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(cls,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


/**
@brief 交换不同类中两个  对象方法    友好提示:自定义的方法可以写在任何的自定义类中 ）
@param originalCls 被交换的类
@param swizzledCls 用来交换的类
@param originalSelector 被交换的方法
@param swizzledSelector 用来交换的方法
  */
- (void)swizzleDifferentClassInstanceMethodWithOriCls:(Class)originalCls swiCls:(Class)swizzledCls oriSel:(SEL)originalSelector swiSel:(SEL)swizzledSelector {
    if (!originalCls || !swizzledCls) {
        NSLog(@"交换方法失败--请保证交换的类名不为空");
        return;
    }
    
    if (!originalSelector || !swizzledSelector) {
        NSLog(@"交换方法失败--请保证交换的方法名不为空");
        return;
    }
    
    //通过class_getClassMethod 获取两个方法Method
    Method originalMethod = class_getInstanceMethod(originalCls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledCls, swizzledSelector);
    
    //交换之前，先对自定义方法进行添加
    BOOL didAddMethod = class_addMethod(originalCls,
                                        swizzledSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    //如果添加成功，则进行交换
    if (didAddMethod) {
        method_exchangeImplementations(originalMethod, class_getInstanceMethod(originalCls, swizzledSelector));
    } else {
        NSLog(@"交换方法失败--添加方法失败");
    }
    
}

/**
@brief 交换不同类中两个  类方法 （  友好提示:自定义的方法可以写在任何的自定义类中 ）
@param originalCls 被交换的类
@param swizzledCls 用来交换的类
@param originalSelector 被交换的方法
@param swizzledSelector 用来交换的方法
  */
- (void)swizzleDifferentClassClassMethodWithOriCls:(Class)originalCls swiCls:(Class)swizzledCls oriSel:(SEL)originalSelector   swiSel:(SEL)swizzledSelector {
    if (!originalCls || !swizzledCls) {
        NSLog(@"交换方法失败--请保证交换的类名不为空");
        return;
    }
    
    if (!originalSelector || !swizzledSelector) {
        NSLog(@"交换方法失败--请保证交换的方法名不为空");
        return;
    }
    //获取元类对象，因为类方法是存在于元类对象当中的
    Class originalMetaCls = object_getClass(originalCls);
    Class swizzledMetaCls = object_getClass(swizzledCls);
    
    //通过class_getClassMethod 获取两个方法Method
    Method originalMethod = class_getClassMethod(originalMetaCls, originalSelector);
    Method swizzledMethod = class_getClassMethod(swizzledMetaCls, swizzledSelector);
    
    //交换之前，先对自定义方法进行添加
    BOOL didAddMethod = class_addMethod(originalMetaCls,
                                        swizzledSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    //如果添加成功，则进行交换
    if (didAddMethod) {
        method_exchangeImplementations(originalMethod, class_getClassMethod(originalMetaCls, swizzledSelector));
    } else {
        NSLog(@"交换方法失败--添加方法失败");
    }
    
}

@end
