//
//  UITextView+RTL.h
//  Base
//
//  Created by 胡灿 on 2024/11/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITextView (RTL)

/// 自定义 RTL 文本属性：
/// - 设置时自动带上方向字符（RLI...PDI 整体包裹，命中 keepLTR 正则的 LTR 片段用 LRE...PDF 保护）；
/// - 读取时自动去除全部方向字符。
///
/// 系统的 text/attributedText 不做任何篡改，始终与 textStorage 及编辑代理回调中的 range 保持同一坐标系；
/// 需要「干净文本」时请使用 RTLText。
@property (nonatomic, copy, nullable) NSString *RTLText;

@end

NS_ASSUME_NONNULL_END
