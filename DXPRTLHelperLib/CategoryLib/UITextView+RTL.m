//
//  UITextView+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/8.
//

#import "UITextView+RTL.h"
#import "RTLTools.h"
#import "RTLDirectionMarks.h"
#import <objc/runtime.h>

@implementation UITextView (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithFrame:) swizzledSEL:@selector(initRTLWithFrame:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithCoder:) swizzledSEL:@selector(initRTLWithCoder:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setTextAlignment:) swizzledSEL:@selector(RTLSetTextAlignment:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setAttributedText:) swizzledSEL:@selector(RTLSetAttributedText:) isInstanceMethod:YES];
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
        [self RTLRegisterTextDidChangeNotification];
        if ([RTLTools canDoRTLWork]) {
            self.textAlignment = NSTextAlignmentLeft;  // default
        } else {
//            self.textAlignment = NSTextAlignmentLeft;
        }
    }
    return self;
}

- (instancetype)initRTLWithCoder:(NSCoder *)coder
{
    self = [self initRTLWithCoder:coder];
    if (self) {
        [self RTLRegisterTextDidChangeNotification];
    }
    return self;
}

/// 注册文本变更通知（selector 形式注册，iOS 9+ 在 self 释放时自动移除，无需 dealloc 处理）
- (void)RTLRegisterTextDidChangeNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(RTLTextDidChange:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];
}

/// 文本发生变更（用户编辑或直接 setText:）时，使保存的原始 attributedText 失效，getter 回退到真实文本。
/// 注意：RTLSetAttributedText: 内部的最终赋值处于 setEnableRTLCategoryWork:NO 保护窗内，
/// 该通知同步触发时 canDoRTLWork 为 NO，不会误清刚保存的原始值。
- (void)RTLTextDidChange:(NSNotification *)notification {
    if (![RTLTools canDoRTLWork]) {
        return;
    }
    self.RTLOriginAttributedText = nil;
}

- (void)RTLSetTextAlignment:(NSTextAlignment)textAlignment {
    // UITextView.textAlignment 会影响到 text
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
        [RTLTools setEnableRTLCategoryWork:NO];
        [self RTLSetTextAlignment:textAlignment];
        [RTLTools setEnableRTLCategoryWork:YES];
    } else {
        [self RTLSetTextAlignment:textAlignment];
    }
}

#pragma mark - RTLText

/// 设置时自动带上方向字符，读取时自动去除方向字符。
/// 系统 text 不做任何篡改：可编辑控件内嵌隔离字符会破坏光标/删除/IME 行为，
/// 且系统的 text 与编辑代理回调中的 range 必须保持同一坐标系（均为存储坐标）。
- (NSString *)RTLText {
    return [RTLTools removeDirectionMask:self.text];
}

- (void)setRTLText:(NSString *)text {
    if ([RTLTools canDoRTLWork]) {
        // 直接设置文本会使保存的原始 attributedText 失效
        self.RTLOriginAttributedText = nil;
    }
    if (![RTLTools canDoRTLWork] || text.length == 0) {
        self.text = text;
        return;
    }
    self.text = RTL_WRAP_RTL([RTLTools rtlStringWithKeepLtrRegular:text]);
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
    self.RTLOriginAttributedText = attributedText;
    NSRange attrsRange = NSMakeRange(0, attributedText.length);
    NSMutableAttributedString *newAttributeText = [[NSMutableAttributedString alloc] initWithString:attributedText.string];
    [attributedText enumerateAttributesInRange:attrsRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        NSMutableParagraphStyle *para = [[attrs valueForKey:NSParagraphStyleAttributeName] mutableCopy];
        NSMutableDictionary *newAttrs = [attrs mutableCopy];
        if (para) {
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
            [newAttrs setValue:para forKey:NSParagraphStyleAttributeName];
        }
        [newAttributeText addAttributes:newAttrs range:range];
    }];
    // 头部标记继承内容首字符的属性（含段落样式），避免裸插入字符抢占段落首个位置导致 alignment 失效
    NSDictionary *headAttrs = newAttributeText.length > 0 ? [newAttributeText attributesAtIndex:0 effectiveRange:NULL] : nil;
    NSAttributedString *rtlMark = [[NSAttributedString alloc] initWithString:RTLRIGHTToLEFTIsolate attributes:headAttrs];
    [newAttributeText insertAttributedString:rtlMark atIndex:0];
    // 尾部标记继承内容末字符的属性
    NSDictionary *tailAttrs = newAttributeText.length > 0 ? [newAttributeText attributesAtIndex:newAttributeText.length - 1 effectiveRange:NULL] : nil;
    NSAttributedString *rtlEndMark = [[NSAttributedString alloc] initWithString:RTLPopDirectionalIsolate attributes:tailAttrs];
    [newAttributeText appendAttributedString:rtlEndMark];
    [RTLTools setEnableRTLCategoryWork:NO];
    [self RTLSetAttributedText:[RTLTools rtlAttributedStringWithKeepLtrRegular:newAttributeText]];
    [RTLTools setEnableRTLCategoryWork:YES];
}

@end
