//
//  UITextField+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/6.
//

#import "UITextField+RTL.h"
#import "RTLTools.h"

@implementation UITextField (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithFrame:) swizzledSEL:@selector(initRTLWithFrame:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setTextAlignment:) swizzledSEL:@selector(RTLSetTextAlignment:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setAttributedText:) swizzledSEL:@selector(RTLSetAttributedText:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setPlaceholder:) swizzledSEL:@selector(RTLSetPlaceholder:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setAttributedPlaceholder:) swizzledSEL:@selector(RTLSetAttributedPlaceholder:) isInstanceMethod:YES];
    });
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

- (void)RTLSetAttributedText:(NSAttributedString *)attributedText {
    if (![RTLTools canDoRTLWork] || attributedText.length == 0) {
        [self RTLSetAttributedText:attributedText];
        return;
    }
   
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
    [RTLTools setEnableRTLCategoryWork:NO];
    [self RTLSetAttributedText:newAttributeText];
    [RTLTools setEnableRTLCategoryWork:YES];

}

- (void)RTLSetPlaceholder:(NSString *)placeholder {
    if ([RTLTools canDoRTLWork]) {
        NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{}];
        self.attributedPlaceholder = attributedPlaceholder;
    } else {
        [self RTLSetPlaceholder:placeholder];
    }
}

- (void)RTLSetAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder {
    if (![RTLTools canDoRTLWork] || attributedPlaceholder.length == 0) {
        [self RTLSetAttributedPlaceholder:attributedPlaceholder];
        return;
    }
    
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
    [RTLTools setEnableRTLCategoryWork:NO];
    [self RTLSetAttributedPlaceholder:newAttributePlaceholder];
    [RTLTools setEnableRTLCategoryWork:YES];
}

@end
