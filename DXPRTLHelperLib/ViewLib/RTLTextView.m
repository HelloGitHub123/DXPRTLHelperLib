//
//  RTLTextView.m
//  Base
//
//  Created by 胡灿 on 2026/10/21.
//

#import "RTLTextView.h"
#import "RTLTools.h"

#pragma mark - RTLTextViewDelegateProxy

/// UITextView 系统代理拦截器：
/// 1. 带 range 的代理方法：把 range 从存储坐标转换为 RTLText 坐标后，优先走 RTL 前缀实现；
/// 2. 其余代理方法（含 UIScrollViewDelegate）：通过消息转发透传，优先 RTL 前缀实现，其次原方法。
@interface RTLTextViewDelegateProxy : NSObject <UITextViewDelegate>

@property (nonatomic, weak) RTLTextView *textView;
@property (nonatomic, weak) id<RTLTextViewDelegate> target;

@end

@implementation RTLTextViewDelegateProxy

/// textViewDidChange: -> RTLTextViewDidChange:
- (SEL)rtlPrefixedSelectorForSelector:(SEL)selector {
    NSString *selectorString = NSStringFromSelector(selector);
    if (selectorString.length == 0) {
        return NULL;
    }
    NSString *rtlSelectorString = [NSString stringWithFormat:@"RTL%@%@",
                                   [[selectorString substringToIndex:1] uppercaseString],
                                   [selectorString substringFromIndex:1]];
    return NSSelectorFromString(rtlSelectorString);
}

#pragma mark 带 range 的代理方法：坐标转换

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([self.target respondsToSelector:@selector(RTLTextView:shouldChangeTextInRange:replacementText:)]) {
        NSRange rtlRange = [RTLTools unmaskedRangeFromMaskedRange:range inMaskedText:textView.text ?: @""];
        return [self.target RTLTextView:self.textView shouldChangeTextInRange:rtlRange replacementText:text];
    }
    if ([self.target respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        return [self.target textView:textView shouldChangeTextInRange:range replacementText:text];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([self.target respondsToSelector:@selector(RTLTextView:shouldInteractWithURL:inRange:interaction:)]) {
        NSRange rtlRange = [RTLTools unmaskedRangeFromMaskedRange:characterRange inMaskedText:textView.text ?: @""];
        return [self.target RTLTextView:self.textView shouldInteractWithURL:URL inRange:rtlRange interaction:interaction];
    }
    if ([self.target respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:interaction:)]) {
        return [self.target textView:textView shouldInteractWithURL:URL inRange:characterRange interaction:interaction];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([self.target respondsToSelector:@selector(RTLTextView:shouldInteractWithTextAttachment:inRange:interaction:)]) {
        NSRange rtlRange = [RTLTools unmaskedRangeFromMaskedRange:characterRange inMaskedText:textView.text ?: @""];
        return [self.target RTLTextView:self.textView shouldInteractWithTextAttachment:textAttachment inRange:rtlRange interaction:interaction];
    }
    if ([self.target respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:interaction:)]) {
        return [self.target textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange interaction:interaction];
    }
    return YES;
}

#pragma mark 其余代理方法：通用转发

/// UIKit 调用代理前会先 respondsToSelector: 检查，需要把 target 实现的方法也回答为 YES
- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    if ([self.target respondsToSelector:aSelector]) {
        return YES;
    }
    SEL rtlSelector = [self rtlPrefixedSelectorForSelector:aSelector];
    return rtlSelector && [self.target respondsToSelector:rtlSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (signature) {
        return signature;
    }
    SEL rtlSelector = [self rtlPrefixedSelectorForSelector:aSelector];
    if (rtlSelector && [self.target respondsToSelector:rtlSelector]) {
        return [(NSObject *)self.target methodSignatureForSelector:rtlSelector];
    }
    return [(NSObject *)self.target methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL rtlSelector = [self rtlPrefixedSelectorForSelector:invocation.selector];
    if (rtlSelector && [self.target respondsToSelector:rtlSelector]) {
        // RTL 前缀方法与原方法参数布局一致，仅方法名不同，直接换 selector 转发
        invocation.selector = rtlSelector;
        [invocation invokeWithTarget:self.target];
        return;
    }
    if ([self.target respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.target];
    }
}

@end

#pragma mark - RTLTextView

@implementation RTLTextView {
    RTLTextViewDelegateProxy *_RTLDelegateProxy;
}

- (void)setDelegate:(id<UITextViewDelegate>)delegate {
    if (!delegate) {
        _RTLDelegateProxy = nil;
        [super setDelegate:nil];
        return;
    }
    if (!_RTLDelegateProxy) {
        _RTLDelegateProxy = [[RTLTextViewDelegateProxy alloc] init];
        _RTLDelegateProxy.textView = self;
    }
    _RTLDelegateProxy.target = (id<RTLTextViewDelegate>)delegate;
    // 系统 delegate 是 weak 引用，代理对象由 self 持有
    [super setDelegate:_RTLDelegateProxy];
}

- (id<UITextViewDelegate>)delegate {
    return _RTLDelegateProxy.target ?: [super delegate];
}

- (NSRange)RTLSelectedRange {
    return [RTLTools unmaskedRangeFromMaskedRange:self.selectedRange inMaskedText:self.text ?: @""];
}

- (void)setRTLSelectedRange:(NSRange)RTLSelectedRange {
    self.selectedRange = [RTLTools maskedRangeFromUnmaskedRange:RTLSelectedRange inMaskedText:self.text ?: @""];
}

@end
