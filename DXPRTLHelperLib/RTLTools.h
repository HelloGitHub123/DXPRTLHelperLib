//
//  RTLTools.h
//  Base
//
//  Created by 胡灿 on 2024/11/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTLTools : NSObject

+ (BOOL)canDoRTLWork;

+ (void)methodSwizzlingWithClass:(Class)cls oriSEL:(SEL)oriSEL swizzledSEL:(SEL)swizzledSEL isInstanceMethod:(BOOL)isInstanceMethod;

+ (UIEdgeInsets)RTLEdgeInsetsWithInsets:(UIEdgeInsets)insets;

+ (UIRectCorner)RTLRectCornersWithCorners:(UIRectCorner)corners;

+ (BOOL)evaluateImgToReverse:(NSString *)imgName;

+ (CGRect)getFrame:(CGRect)frame withView:(UIView *)view;

+ (CGRect)getFrame:(CGRect)frame withSuperBounds:(CGRect)superBounds;

+ (BOOL)isAtomView:(UIView *)view;

+ (UISemanticContentAttribute)currentLanSemanticStyle;

+ (void)setEnableRTLCategoryWork:(BOOL)enabled;

+ (NSString *)getLocale;

#pragma mark - Text Direction Detection

/// 判断字符串是否以 RTL 语言开头
/// 支持语言: 阿拉伯文、希伯来文、叙利亚文、标记符号、N'Ko 等
/// @param text 待检测的字符串
/// @return YES 表示以 RTL 语言开头，NO 表示不是
+ (BOOL)isStartingWithRTL:(NSString *)text;

/// 判断字符串是否以 LTR 语言开头
/// @param text 待检测的字符串
/// @return YES 表示以 LTR 语言开头（英文），NO 表示不是
+ (BOOL)isStartingWithLTR:(NSString *)text;

/// 判断字符串是否全部为 RTL 语言
/// 支持语言: 阿拉伯文、希伯来文、叙利亚文、标记符号、N'Ko 等
/// 允许数字、空格、标点等中性字符混合
/// @param text 待检测的字符串
/// @return YES 表示全部为 RTL 语言，NO 表示不是
+ (BOOL)isAllRTL:(NSString *)text;

/// 判断字符串是否全部为 LTR 语言
/// 允许数字、空格、标点等中性字符混合
/// @param text 待检测的字符串
/// @return YES 表示全部为 LTR 语言（英文），NO 表示不是
+ (BOOL)isAllLTR:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
