//
//  RTLDirectionMarks.h
//  Base
//
//  Created by 胡灿 on 2024/06/19.
//

#import <Foundation/Foundation.h>

#pragma mark - Embedding Direction Characters (推荐使用隔离字符)

/// LEFT-TO-RIGHT EMBEDDING (LRE) - 强制后续文本从左到右显示，需要 PDF 结束
FOUNDATION_EXPORT NSString * _Nonnull const RTLLEFTToRIGHTEmbedding;

/// RIGHT-TO-LEFT EMBEDDING (RLE) - 强制后续文本从右到左显示，需要 PDF 结束
FOUNDATION_EXPORT NSString * _Nonnull const RTLRIGHTToLEFTEmbedding;

/// POP DIRECTIONAL FORMATTING (PDF) - 结束嵌入或覆盖方向
FOUNDATION_EXPORT NSString * _Nonnull const RTLPopDirectionalFormatting;

#pragma mark - Override Direction Characters

/// LEFT-TO-RIGHT OVERRIDE (LRO) - 强制覆盖后续文本为从左到右，需要 PDF 结束
FOUNDATION_EXPORT NSString * _Nonnull const RTLLEFTToRIGHTOverride;

/// RIGHT-TO-LEFT OVERRIDE (RLO) - 强制覆盖后续文本为从右到左，需要 PDF 结束
FOUNDATION_EXPORT NSString * _Nonnull const RTLRIGHTToLEFTOverride;

#pragma mark - Isolation Direction Characters (现代推荐方案)

/// LEFT-TO-RIGHT ISOLATE (LRI) - 隔离并标记文本为从左到右，需要 PDI 结束
FOUNDATION_EXPORT NSString * _Nonnull const RTLLEFTToRIGHTIsolate;

/// RIGHT-TO-LEFT ISOLATE (RLI) - 隔离并标记文本为从右到左，需要 PDI 结束
FOUNDATION_EXPORT NSString * _Nonnull const RTLRIGHTToLEFTIsolate;

/// FIRST STRONG ISOLATE (FSI) - 根据第一个强方向字符自动隔离，需要 PDI 结束
FOUNDATION_EXPORT NSString * _Nonnull const RTLFirstStrongIsolate;

/// POP DIRECTIONAL ISOLATE (PDI) - 结束隔离指令
FOUNDATION_EXPORT NSString * _Nonnull const RTLPopDirectionalIsolate;

#pragma mark - Direction Mark Characters (零宽度标记)

/// LEFT-TO-RIGHT MARK (LRM) - 零宽度字符，表示后续文本方向为从左到右
FOUNDATION_EXPORT NSString * _Nonnull const RTLLEFTToRIGHTMark;

/// RIGHT-TO-LEFT MARK (RLM) - 零宽度字符，表示后续文本方向为从右到左
FOUNDATION_EXPORT NSString * _Nonnull const RTLRIGHTToLEFTMark;

/// ARABIC LETTER MARK (ALM) - 阿拉伯文字标记，类似于 RLM，专为阿拉伯文设计
FOUNDATION_EXPORT NSString * _Nonnull const RTLArabicLetterMark;

#pragma mark - Zero-Width Characters

/// ZERO WIDTH SPACE - 零宽度空格（用于分词）
FOUNDATION_EXPORT NSString * _Nonnull const RTLZeroWidthSpace;

/// ZERO WIDTH NON-JOINER (ZWNJ) - 阻止字符连接
FOUNDATION_EXPORT NSString * _Nonnull const RTLZeroWidthNonJoiner;

/// ZERO WIDTH JOINER (ZWJ) - 强制字符连接
FOUNDATION_EXPORT NSString * _Nonnull const RTLZeroWidthJoiner;

#pragma mark - Utility Macros

/// 使用隔离字符包装 LTR 文本（现代推荐方式）
#define RTL_WRAP_LTR(text) [NSString stringWithFormat:@"%@%@%@", RTLLEFTToRIGHTIsolate, text, RTLPopDirectionalIsolate]

/// 使用隔离字符包装 RTL 文本（现代推荐方式）
#define RTL_WRAP_RTL(text) [NSString stringWithFormat:@"%@%@%@", RTLRIGHTToLEFTIsolate, text, RTLPopDirectionalIsolate]

/// 使用嵌入字符包装 LTR 文本（传统方式）
#define RTL_EMBED_LTR(text) [NSString stringWithFormat:@"%@%@%@", RTLLEFTToRIGHTEmbedding, text, RTLPopDirectionalFormatting]

/// 使用嵌入字符包装 RTL 文本（传统方式）
#define RTL_EMBED_RTL(text) [NSString stringWithFormat:@"%@%@%@", RTLRIGHTToLEFTEmbedding, text, RTLPopDirectionalFormatting]
