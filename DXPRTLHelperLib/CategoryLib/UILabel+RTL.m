//
//  UILabel+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/4.
//

#import "UILabel+RTL.h"
#import "RTLTools.h"
#import "RTLDirectionMarks.h"
#import <objc/runtime.h>

@implementation UILabel (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithFrame:) swizzledSEL:@selector(initRTLWithFrame:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setTextAlignment:) swizzledSEL:@selector(RTLSetTextAlignment:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setText:) swizzledSEL:@selector(RTLSetText:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setAttributedText:) swizzledSEL:@selector(RTLSetAttributedText:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(text) swizzledSEL:@selector(RTLText) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(attributedText) swizzledSEL:@selector(RTLAttributedText) isInstanceMethod:YES];
    });
}

static const char RTLOriginAttributedTextStr = '\0';

- (NSAttributedString *)RTLOriginAttributedText {
    id originAttributedText = objc_getAssociatedObject(self, &RTLOriginAttributedTextStr);
    return originAttributedText;
}

- (void)setRTLOriginAttributedText:(NSAttributedString *)originAttributedText {
    if (self.RTLOriginAttributedText != originAttributedText) {
        objc_setAssociatedObject(self, &RTLOriginAttributedTextStr, originAttributedText, OBJC_ASSOCIATION_RETAIN);
    }
}

- (instancetype)initRTLWithFrame:(CGRect)frame
{
    self = [self initRTLWithFrame:frame];
    if (self) {
        if ([RTLTools canDoRTLWork]) {
            self.textAlignment = NSTextAlignmentLeft;  // default
        } else {
//            self.textAlignment = NSTextAlignmentLeft;
        }
    }
    return self;
}

- (void)RTLSetTextAlignment:(NSTextAlignment)textAlignment {
    if ([RTLTools canDoRTLWork]) {
        switch (textAlignment) {
            case NSTextAlignmentLeft:
                textAlignment = NSTextAlignmentRight;
                break;
            case NSTextAlignmentRight:
                textAlignment = NSTextAlignmentLeft;
                break;
            case NSTextAlignmentNatural:
                textAlignment = NSTextAlignmentRight;
                break;
            default:
                break;
        }
    }
    [self RTLSetTextAlignment:textAlignment];
}

- (NSString *)RTLText {
    if (![RTLTools canDoRTLWork]) {
        return [self RTLText];  // 不需要RTL处理，返回原始文本
    }

    // 优先处理 attributedText 的情况：返回原始 attributedString 的字符串
    if (self.RTLOriginAttributedText) {
        return self.RTLOriginAttributedText.string;
    }

    // 存储文本带方向标记，读取时去除（NSString 无属性概念，边读边剥与原稿等价）；nil 保持 nil 语义
    NSString *origin = [self RTLText];
    return origin ? [RTLTools removeDirectionMask:origin] : origin;
}

- (void)RTLSetText:(NSString *)text {
    if (!text) {
        return;
    }
    if (![RTLTools canDoRTLWork]) {
        [self RTLSetText:text];
        return;
    }
    [self RTLSetText:RTL_WRAP_RTL([RTLTools rtlStringWithKeepLtrRegular:text])];
}

- (NSAttributedString *)RTLAttributedText {
    if (![RTLTools canDoRTLWork]) {
        return [self RTLAttributedText];
    }
    return self.RTLOriginAttributedText;
}

- (void)RTLSetAttributedText:(NSAttributedString *)attributedText {
    if (!attributedText) {
        return;
    }
    if (![RTLTools canDoRTLWork]) {
        [self RTLSetAttributedText:attributedText];
        return;
    }
    // 外面传进来的内容可能已带方向字符，保存时统一去掉（保留其余属性样式），保证 getter 返回干净内容
    self.RTLOriginAttributedText = [RTLTools removeDirectionMaskFromAttributedString:attributedText];
    NSRange attrsRange = NSMakeRange(0, attributedText.length);
    NSMutableAttributedString *newAttributeText = [[NSMutableAttributedString alloc] initWithString:attributedText.string];
    // 段落样式存在但没显式对齐（natural，比如只设了行距）时，label 自身的 textAlignment 不再生效，
    // 用视图当前对齐（已被 RTLSetTextAlignment: 翻转，RTL 坐标）兜底；
    // 完全没有段落样式的区间不补：由 label 自身的 textAlignment 兜底，且新建段落会覆盖 lineBreakMode
    NSTextAlignment viewAlignment = self.textAlignment == NSTextAlignmentNatural ? NSTextAlignmentRight : self.textAlignment;
    [attributedText enumerateAttributesInRange:attrsRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        NSMutableParagraphStyle *para = [[attrs valueForKey:NSParagraphStyleAttributeName] mutableCopy];
        NSMutableDictionary *newAttrs = [attrs mutableCopy];
        if (para) {
            if (para.alignment == NSTextAlignmentNatural && viewAlignment != NSTextAlignmentNatural) {
                // 没有显式对齐：视图对齐已是 RTL 坐标，直接使用，不再翻转
                para.alignment = viewAlignment;
            } else {
                // 显式对齐是业务的设计时意图（LTR 坐标），需要翻转
                NSTextAlignment textAlignment = para.alignment;
                switch (para.alignment) {
                    case NSTextAlignmentLeft:
                        textAlignment = NSTextAlignmentRight;
                        break;
                    case NSTextAlignmentRight:
                        textAlignment = NSTextAlignmentLeft;
                        break;
                    case NSTextAlignmentNatural:
                        textAlignment = NSTextAlignmentRight;
                        break;
                    default:
                        break;
                }
                para.alignment = textAlignment;
            }
            [newAttrs setValue:para forKey:NSParagraphStyleAttributeName];
        }
        [newAttributeText addAttributes:newAttrs range:range];
    }];
    // 头部标记继承内容首字符的属性（含段落样式），避免裸插入字符抢占段落首个位置导致 alignment 失效
    NSDictionary *headAttrs = newAttributeText.length > 0 ? [RTLTools sanitizedAttributesForDirectionMark:[newAttributeText attributesAtIndex:0 effectiveRange:NULL]] : nil;
    NSAttributedString *rtlMark = [[NSAttributedString alloc] initWithString:RTLRIGHTToLEFTIsolate attributes:headAttrs];
    [newAttributeText insertAttributedString:rtlMark atIndex:0];
    // 尾部标记继承内容末字符的属性
    NSDictionary *tailAttrs = newAttributeText.length > 0 ? [RTLTools sanitizedAttributesForDirectionMark:[newAttributeText attributesAtIndex:newAttributeText.length - 1 effectiveRange:NULL]] : nil;
    NSAttributedString *rtlEndMark = [[NSAttributedString alloc] initWithString:RTLPopDirectionalIsolate attributes:tailAttrs];
    [newAttributeText appendAttributedString:rtlEndMark];
    [self RTLSetAttributedText:[RTLTools rtlAttributedStringWithKeepLtrRegular:newAttributeText]];
}

@end
