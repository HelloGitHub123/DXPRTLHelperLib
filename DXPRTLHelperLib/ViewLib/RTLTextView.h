//
//  RTLTextView.h
//  Base
//
//  Created by 胡灿 on 2026/10/21.
//

#import <UIKit/UIKit.h>
#import "UITextView+RTL.h"

@class RTLTextView;

NS_ASSUME_NONNULL_BEGIN

/// 与 UITextViewDelegate 一一对应的 RTL 版本代理协议，方法名前均加 RTL 前缀：
///
/// 1. 回调里通过 textView.RTLText 读写文本（设置自动带上方向字符，读取自动去除方向字符）；
/// 2. 涉及 range 的参数均为相对于 RTLText（去除方向字符后的文本）的位置；
/// 3. 未实现 RTL 前缀方法时，回退调用 UITextViewDelegate 原始方法（此时 range 为原始存储坐标）；
/// 4. UIScrollViewDelegate 系列方法不做处理，原样透传。
@protocol RTLTextViewDelegate <UITextViewDelegate>

@optional

- (BOOL)RTLTextViewShouldBeginEditing:(RTLTextView *)textView;
- (BOOL)RTLTextViewShouldEndEditing:(RTLTextView *)textView;

- (void)RTLTextViewDidBeginEditing:(RTLTextView *)textView;
- (void)RTLTextViewDidEndEditing:(RTLTextView *)textView;

/// range 为相对于 RTLText（去除方向字符后的文本）的位置
- (BOOL)RTLTextView:(RTLTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;

- (void)RTLTextViewDidChange:(RTLTextView *)textView;

/// 选中区域变化；通过 textView.RTLSelectedRange 获取相对于 RTLText 的选中区域
- (void)RTLTextViewDidChangeSelection:(RTLTextView *)textView;

/// characterRange 为相对于 RTLText（去除方向字符后的文本）的位置
- (BOOL)RTLTextView:(RTLTextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction API_AVAILABLE(ios(10.0));
- (BOOL)RTLTextView:(RTLTextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction API_AVAILABLE(ios(10.0));

@end

/// 继承自 UITextView，内部通过代理拦截把 UITextViewDelegate 回调转换为 RTLTextViewDelegate 回调。
///
/// delegate 正常赋值即可（对象需遵循 RTLTextViewDelegate）。
/// 文本读写约定：
/// - text/attributedText：原始存储内容（含方向字符），与系统代理 range 坐标一致；
/// - RTLText：去除方向字符后的文本（设置时自动带上方向字符）。
@interface RTLTextView : UITextView

@property (nullable, nonatomic, weak) id<RTLTextViewDelegate> delegate;

/// 当前选中区域（相对于 RTLText 的位置）；设置时会转换回存储坐标
@property (nonatomic) NSRange RTLSelectedRange;

@end

NS_ASSUME_NONNULL_END
