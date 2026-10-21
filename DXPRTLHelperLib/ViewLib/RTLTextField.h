//
//  RTLTextField.h
//  Base
//
//  Created by 胡灿 on 2026/10/21.
//

#import <UIKit/UIKit.h>
#import "UITextField+RTL.h"

@class RTLTextField;

NS_ASSUME_NONNULL_BEGIN

/// 与 UITextFieldDelegate 一一对应的 RTL 版本代理协议，方法名前均加 RTL 前缀：
///
/// 1. 回调里通过 textField.RTLText 读写文本（设置自动带上方向字符，读取自动去除方向字符）；
/// 2. 涉及 range 的参数均为相对于 RTLText（去除方向字符后的文本）的位置；
/// 3. 未实现 RTL 前缀方法时，回退调用 UITextFieldDelegate 原始方法（此时 range 为原始存储坐标）。
@protocol RTLTextFieldDelegate <UITextFieldDelegate>

@optional

- (BOOL)RTLTextFieldShouldBeginEditing:(RTLTextField *)textField;
- (void)RTLTextFieldDidBeginEditing:(RTLTextField *)textField;
- (BOOL)RTLTextFieldShouldEndEditing:(RTLTextField *)textField;
- (void)RTLTextFieldDidEndEditing:(RTLTextField *)textField;
- (void)RTLTextFieldDidEndEditing:(RTLTextField *)textField reason:(UITextFieldDidEndEditingReason)reason API_AVAILABLE(ios(10.0));

/// range 为相对于 RTLText（去除方向字符后的文本）的位置
- (BOOL)RTLTextField:(RTLTextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

- (BOOL)RTLTextFieldShouldClear:(RTLTextField *)textField;
- (BOOL)RTLTextFieldShouldReturn:(RTLTextField *)textField;

@end

/// 继承自 UITextField，内部通过代理拦截把 UITextFieldDelegate 回调转换为 RTLTextFieldDelegate 回调。
///
/// delegate 正常赋值即可（对象需遵循 RTLTextFieldDelegate）。
/// 文本读写约定：
/// - text/attributedText：原始存储内容（含方向字符），与系统代理 range 坐标一致；
/// - RTLText：去除方向字符后的文本（设置时自动带上方向字符）。
@interface RTLTextField : UITextField

@property (nullable, nonatomic, weak) id<RTLTextFieldDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
