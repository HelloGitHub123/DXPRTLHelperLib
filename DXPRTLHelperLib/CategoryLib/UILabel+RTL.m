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

static const char RTLOriginTextStr = '\0';

- (NSString *)RTLOriginText {
    id originText = objc_getAssociatedObject(self, &RTLOriginTextStr);
    return originText;
}

- (void)setRTLOriginText:(NSString *)originText {
    if (self.RTLOriginText != originText) {
        objc_setAssociatedObject(self, &RTLOriginTextStr, originText, OBJC_ASSOCIATION_RETAIN);
    }
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
        return [self RTLText];
    }
    return self.RTLOriginText;
}

- (void)RTLSetText:(NSString *)text {
    if (![RTLTools canDoRTLWork] || text.length == 0) {
        [self RTLSetText:text];
        return;
    }
    self.RTLOriginText = text;
    [self RTLSetText:RTL_EMBED_RTL(text)];
}

- (NSAttributedString *)RTLAttributedText {
    if (![RTLTools canDoRTLWork]) {
        return [self RTLAttributedText];
    }
    return self.RTLOriginAttributedText;
}

- (void)RTLSetAttributedText:(NSAttributedString *)attributedText {
    if (![RTLTools canDoRTLWork] || attributedText.length == 0) {
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
    NSAttributedString *rtlMark = [[NSAttributedString alloc] initWithString:RTLRIGHTToLEFTIsolate];
    [newAttributeText insertAttributedString:rtlMark atIndex:0];
    NSAttributedString *rtlEndMark = [[NSAttributedString alloc] initWithString:RTLPopDirectionalIsolate];
    [newAttributeText appendAttributedString:rtlEndMark];
    [self RTLSetAttributedText:newAttributeText];
}

@end
