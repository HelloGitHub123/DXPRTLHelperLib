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

+ (NSString *)rtlStringWithKeepLtrRegular:(NSString *)text;

+ (NSAttributedString *)rtlAttributedStringWithKeepLtrRegular:(NSAttributedString *)attrText;

#pragma mark - Direction Mask Removal

/// 移除字符串中所有的方向控制字符（LRM/RLM、LRE/RLE/PDF、LRO/RLO、LRI/RLI/FSI/PDI）
/// - Parameter text: 需要处理的字符串，传 nil 时返回 @""
+ (NSString *)removeDirectionMask:(NSString *)text;

/// 方向标记字符可用的属性：在继承内容样式的基础上剔除附件/链接
/// （标记字符带上附件/链接属性时，会被渲染成图片或变成可点击区域）
+ (NSDictionary<NSAttributedStringKey, id> *)sanitizedAttributesForDirectionMark:(NSDictionary<NSAttributedStringKey, id> *)attrs;

/// 只移除字符串**首尾**的方向控制字符，中间的保留
///
/// 与 removeDirectionMask: 的区别：后者会移除整个字符串中所有的方向掩码
/// - Parameter text: 需要处理的字符串，传 nil 时返回 @""
+ (NSString *)removeEdgesDirectionMask:(NSString *)text;

/// 判断文本首尾是否已带同方向（RTL）的成对包裹符号：
/// RLI…PDI（隔离）、RLE…PDF（嵌入）、RLO…PDF（覆盖）三种任一配对
/// 已带包裹的文本在添加方向符号时应跳过，避免嵌套重复包裹
+ (BOOL)hasRTLDirectionWrap:(NSString *)text;

/// 判断文本首尾是否已带同方向（LTR）的成对包裹符号：
/// LRI…PDI（隔离）、LRE…PDF（嵌入）、LRO…PDF（覆盖）三种任一配对
+ (BOOL)hasLTRDirectionWrap:(NSString *)text;

/// 移除富文本中所有方向控制字符，其余属性（字体/颜色/段落样式等）按原属性连续区间保留
/// - Parameter attrText: 需要处理的富文本
+ (NSAttributedString *)removeDirectionMaskFromAttributedString:(NSAttributedString *)attrText;

/// 将「含方向控制字符文本」中的 range 转换为移除方向控制字符后文本中的 range。
/// 编辑代理回调中的 range 是存储坐标（含方向字符），可用该方法转换为去除方向字符后文本的坐标
/// - Parameters:
///   - maskedRange: 含方向控制字符文本中的 range
///   - maskedText: 含方向控制字符的文本
+ (NSRange)unmaskedRangeFromMaskedRange:(NSRange)maskedRange inMaskedText:(NSString *)maskedText;

/// 将「移除方向控制字符后文本」中的 range 转换回含方向控制字符文本中的 range
/// - Parameters:
///   - unmaskedRange: 移除方向控制字符后文本中的 range
///   - maskedText: 含方向控制字符的文本
+ (NSRange)maskedRangeFromUnmaskedRange:(NSRange)unmaskedRange inMaskedText:(NSString *)maskedText;

/// 退格删除的计算区间（存储坐标）：光标紧贴方向标记时跨过标记串，
/// 把起点落到前一个可见字符上（删除「1 个可见字符 + 其后的标记」），
/// 避免退格只吃掉标记、随后归一化又补回导致可见内容永远删不掉；
/// 光标前无标记时返回标准的 {caret-1, 1}，caret 为 0 返回 {0, 0}（无可删除）
+ (NSRange)backspaceRangeForCaret:(NSUInteger)caretLocation inMaskedText:(NSString *)maskedText;

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
