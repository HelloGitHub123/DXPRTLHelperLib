//
//  UITextView+RTL.h
//  Base
//
//  Created by 胡灿 on 2024/11/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// RTL 适配（外部无感方向字符）：
/// - text/attributedText：设置时自动带上方向字符（RLI...PDI 整体包裹，命中 keepLTR 正则的
///   LTR 片段用 LRE...PDF 保护，已带同方向包裹符号的不重复添加），空文本不加；
/// - text/attributedText：读取时自动去除全部方向字符（attributed 类型保留其余属性样式）；
/// - 输入/删除/剪切/粘贴后自动归一方向字符并保持光标位置；
/// - 复制/剪切到剪贴板的内容不带方向字符；
/// - delegate 正常赋值即可（含 UIScrollViewDelegate 系列透传），shouldChangeTextInRange:/
///   shouldInteractWithURL:/shouldInteractWithTextAttachment: 的 range 为去除方向字符后文本的坐标
///   （输入回调经内部代理转发，读取 delegate 返回该代理对象，方法调用会被转发到原 delegate，
///   请勿做 == 身份比较；非 RTL 环境不装代理，返回原对象）。
@interface UITextView (RTL)

/// 当前选中区域（相对于去除方向字符后的文本）；设置时会转换回存储坐标
@property (nonatomic) NSRange RTLSelectedRange;

@end

NS_ASSUME_NONNULL_END
