//
//  UITextField+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/6.
//

#import "UITextField+RTL.h"
#import "RTLTools.h"
#import "RTLDirectionMarks.h"
#import <objc/runtime.h>

@implementation UITextField (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithFrame:) swizzledSEL:@selector(initRTLWithFrame:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithCoder:) swizzledSEL:@selector(initRTLWithCoder:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setTextAlignment:) swizzledSEL:@selector(RTLSetTextAlignment:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setAttributedText:) swizzledSEL:@selector(RTLSetAttributedText:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(attributedText) swizzledSEL:@selector(RTLAttributedText) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setPlaceholder:) swizzledSEL:@selector(RTLSetPlaceholder:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setAttributedPlaceholder:) swizzledSEL:@selector(RTLSetAttributedPlaceholder:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(placeholder) swizzledSEL:@selector(RTLPlaceholder) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(attributedPlaceholder) swizzledSEL:@selector(RTLAttributedPlaceholder) isInstanceMethod:YES];
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

static const char RTLOriginPlaceholderStr = '\0';

- (NSString *)RTLOriginPlaceholder {
    id originPlaceholder = objc_getAssociatedObject(self, &RTLOriginPlaceholderStr);
    return originPlaceholder;
}

- (void)setRTLOriginPlaceholder:(NSString *)originPlaceholder {
    if (self.RTLOriginPlaceholder != originPlaceholder) {
        objc_setAssociatedObject(self, &RTLOriginPlaceholderStr, originPlaceholder, OBJC_ASSOCIATION_RETAIN);
    }
}

static const char RTLOriginAttributedPlaceholderStr = '\0';

- (NSAttributedString *)RTLOriginAttributedPlaceholder {
    id originAttributedPlaceholder = objc_getAssociatedObject(self, &RTLOriginAttributedPlaceholderStr);
    return originAttributedPlaceholder;
}

- (void)setRTLOriginAttributedPlaceholder:(NSAttributedString *)originAttributedPlaceholder {
    if (self.RTLOriginAttributedPlaceholder != originAttributedPlaceholder) {
        objc_setAssociatedObject(self, &RTLOriginAttributedPlaceholderStr, originAttributedPlaceholder, OBJC_ASSOCIATION_RETAIN);
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
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self];
}

/// 文本发生变更（用户编辑）时，使保存的原始 attributedText 失效，getter 回退到真实文本。
/// 注意：UITextField 仅在用户编辑时发送该通知，代码 setText:/setAttributedText: 不会触发。
- (void)RTLTextDidChange:(NSNotification *)notification {
    if (![RTLTools canDoRTLWork]) {
        return;
    }
    self.RTLOriginAttributedText = nil;
}

- (void)RTLSetTextAlignment:(NSTextAlignment)textAlignment {
    // UITextField.textAlignment 会影响到 text 和 placeholder
    // 但是 placeholder 会走UILabel+RTL.h 中的反转设置
    // 而 text 不会走，因为text不是书写在UILabel上的
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
        // 直接设置文本会使保存的原始 attributedText 失效（UITextField 代码设置文本不触发变更通知，需手动清）
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

- (NSString *)RTLPlaceholder {
    if (![RTLTools canDoRTLWork]) {
        return [self RTLPlaceholder];  // 不需要RTL处理，返回原始placeholder
    }

    // 优先处理 attributedPlaceholder 的情况：返回原始 attributedString 的字符串
    if (self.RTLOriginAttributedPlaceholder) {
        return self.RTLOriginAttributedPlaceholder.string;
    }

    // 未保存过原始值时，直接调用原始方法获取当前 placeholder
    if (!self.RTLOriginPlaceholder || self.RTLOriginPlaceholder.length == 0) {
        return [self RTLPlaceholder];
    }

    // 需要RTL处理时，返回保存的原始placeholder（不含方向标记）
    return self.RTLOriginPlaceholder;
}

- (NSAttributedString *)RTLAttributedPlaceholder {
    if (![RTLTools canDoRTLWork]) {
        return [self RTLAttributedPlaceholder];
    }
    return self.RTLOriginAttributedPlaceholder;
}

- (void)RTLSetPlaceholder:(NSString *)placeholder {
    if ([RTLTools canDoRTLWork]) {
        self.RTLOriginPlaceholder = placeholder;
        NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{}];
        self.attributedPlaceholder = attributedPlaceholder;
    } else {
        [self RTLSetPlaceholder:placeholder];
    }
}

- (void)RTLSetAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder {
    if (!attributedPlaceholder) {
        return;
    }
    if (![RTLTools canDoRTLWork]) {
        [self RTLSetAttributedPlaceholder:attributedPlaceholder];
        return;
    }
    self.RTLOriginAttributedPlaceholder = attributedPlaceholder;

    NSRange attrsRange = NSMakeRange(0, attributedPlaceholder.length);
    NSMutableAttributedString *newAttributePlaceholder = [[NSMutableAttributedString alloc] initWithString:attributedPlaceholder.string];
    [attributedPlaceholder enumerateAttributesInRange:attrsRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
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
        [newAttributePlaceholder addAttributes:newAttrs range:range];
    }];
    // 头部标记继承内容首字符的属性（含段落样式），避免裸插入字符抢占段落首个位置导致 alignment 失效
    NSDictionary *headAttrs = newAttributePlaceholder.length > 0 ? [newAttributePlaceholder attributesAtIndex:0 effectiveRange:NULL] : nil;
    NSAttributedString *rtlMark = [[NSAttributedString alloc] initWithString:RTLRIGHTToLEFTIsolate attributes:headAttrs];
    [newAttributePlaceholder insertAttributedString:rtlMark atIndex:0];
    // 尾部标记继承内容末字符的属性
    NSDictionary *tailAttrs = newAttributePlaceholder.length > 0 ? [newAttributePlaceholder attributesAtIndex:newAttributePlaceholder.length - 1 effectiveRange:NULL] : nil;
    NSAttributedString *rtlEndMark = [[NSAttributedString alloc] initWithString:RTLPopDirectionalIsolate attributes:tailAttrs];
    [newAttributePlaceholder appendAttributedString:rtlEndMark];
    [RTLTools setEnableRTLCategoryWork:NO];
    [self RTLSetAttributedPlaceholder:[RTLTools rtlAttributedStringWithKeepLtrRegular:newAttributePlaceholder]];
    [RTLTools setEnableRTLCategoryWork:YES];
}

@end
