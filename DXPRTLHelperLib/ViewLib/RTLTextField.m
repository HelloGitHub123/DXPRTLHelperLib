//
//  RTLTextField.m
//  Base
//
//  Created by 胡灿 on 2026/10/21.
//

#import "RTLTextField.h"
#import "RTLTools.h"

#pragma mark - RTLTextFieldDelegateProxy

/// UITextField 系统代理拦截器：
/// 1. 带 range 的代理方法：把 range 从存储坐标转换为 RTLText 坐标后，优先走 RTL 前缀实现；
/// 2. 其余代理方法：通过消息转发透传，优先 RTL 前缀实现，其次原方法。
@interface RTLTextFieldDelegateProxy : NSObject <UITextFieldDelegate>

@property (nonatomic, weak) RTLTextField *textField;
@property (nonatomic, weak) id<RTLTextFieldDelegate> target;

@end

@implementation RTLTextFieldDelegateProxy

/// textFieldShouldReturn: -> RTLTextFieldShouldReturn:
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([self.target respondsToSelector:@selector(RTLTextField:shouldChangeCharactersInRange:replacementString:)]) {
        NSRange rtlRange = [RTLTools unmaskedRangeFromMaskedRange:range inMaskedText:textField.text ?: @""];
        return [self.target RTLTextField:self.textField shouldChangeCharactersInRange:rtlRange replacementString:string];
    }
    if ([self.target respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        return [self.target textField:textField shouldChangeCharactersInRange:range replacementString:string];
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

#pragma mark - RTLTextField

@implementation RTLTextField {
    RTLTextFieldDelegateProxy *_RTLDelegateProxy;
}

- (void)setDelegate:(id<UITextFieldDelegate>)delegate {
    if (!delegate) {
        _RTLDelegateProxy = nil;
        [super setDelegate:nil];
        return;
    }
    if (!_RTLDelegateProxy) {
        _RTLDelegateProxy = [[RTLTextFieldDelegateProxy alloc] init];
        _RTLDelegateProxy.textField = self;
    }
    _RTLDelegateProxy.target = (id<RTLTextFieldDelegate>)delegate;
    // 系统 delegate 是 weak 引用，代理对象由 self 持有
    [super setDelegate:_RTLDelegateProxy];
}

- (id<UITextFieldDelegate>)delegate {
    return _RTLDelegateProxy.target ?: [super delegate];
}

@end
