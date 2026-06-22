//
//  UILabel+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/4.
//

#import "UILabel+RTL.h"
#import "RTLTools.h"
#import "RTLDirectionMarks.h"

@implementation UILabel (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithFrame:) swizzledSEL:@selector(initRTLWithFrame:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setTextAlignment:) swizzledSEL:@selector(RTLSetTextAlignment:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setText:) swizzledSEL:@selector(RTLSetText:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setAttributedText:) swizzledSEL:@selector(RTLSetAttributedText:) isInstanceMethod:YES];
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

- (void)RTLSetText:(NSString *)text {
    if (![RTLTools canDoRTLWork] || text.length == 0) {
        [self RTLSetText:text];
        return;
    }
    [self RTLSetText:RTL_EMBED_RTL(text)];
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
    NSAttributedString *rtlMark = [[NSAttributedString alloc] initWithString:RTLRIGHTToLEFTIsolate];
    [newAttributeText insertAttributedString:rtlMark atIndex:0];
    NSAttributedString *rtlEndMark = [[NSAttributedString alloc] initWithString:RTLPopDirectionalIsolate];
    [newAttributeText appendAttributedString:rtlEndMark];
    [self RTLSetAttributedText:newAttributeText];
}

@end
