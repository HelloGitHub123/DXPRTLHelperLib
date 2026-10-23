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

#pragma mark - 系统代理拦截器

/// text 与 RTLStrippedText 交换实现后：text 选择子承载去标记逻辑（外部无感方向字符），
/// RTLStrippedText 选择子承载原始 getter（内部需要含方向字符的存储文本时调用）。
@interface UITextField (RTLInternal)
- (NSString *)RTLStrippedText;
@end

/// UITextField 系统代理拦截器：
/// 1. 带 range 的代理方法：把 range 从存储坐标转换为去除方向字符后的文本坐标后转发；
/// 2. 其余代理方法：通过消息转发原样透传。
/// 代理对象由关联对象持有（系统 delegate 是 weak 引用），外部 delegate 读写无感。
@interface RTLUITextFieldDelegateProxy : NSObject <UITextFieldDelegate>

@property (nonatomic, weak) id<UITextFieldDelegate> target;

@end

@implementation RTLUITextFieldDelegateProxy

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // 存储坐标 → 干净文本坐标；替换文本同样去除方向字符
    if ([self.target respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        NSString *maskedText = [((UITextField *)textField) RTLStrippedText] ?: @"";
        NSRange rtlRange = [RTLTools unmaskedRangeFromMaskedRange:range inMaskedText:maskedText];
        // 退格删除方向标记场景：系统按存储坐标只发「光标前一个字符」（如尾部 PDI），
        // 单删标记是视觉空操作，实际生效的删除是 RTLDeleteBackward 扩展的
        // 「标记串 + 前一个可见字符」。识别特征：转干净坐标后 length 塌缩为 0。
        // 此时按同一 backspaceRangeForCaret: 规则扩展后再转换，
        // 调用方收到的才是与删除结果一致的区间（否则拿到 length=0 的无效区间，判断必失败）
        if (string.length == 0 && range.length == 1 && rtlRange.length == 0) {
            NSRange expandedRange = [RTLTools backspaceRangeForCaret:NSMaxRange(range) inMaskedText:maskedText];
            if (expandedRange.length > 1) {
                rtlRange = [RTLTools unmaskedRangeFromMaskedRange:expandedRange inMaskedText:maskedText];
            }
        }
        NSString *cleanString = [RTLTools removeDirectionMask:string];
        return [self.target textField:textField shouldChangeCharactersInRange:rtlRange replacementString:cleanString];
    }
    return YES;
}

/// UIKit 调用代理前会先 respondsToSelector: 检查，需要把 target 实现的方法也回答为 YES
- (BOOL)respondsToSelector:(SEL)aSelector {
    return [super respondsToSelector:aSelector] || [self.target respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    return signature ?: [(NSObject *)self.target methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([self.target respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.target];
    }
}

@end

@implementation UITextField (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithFrame:) swizzledSEL:@selector(initRTLWithFrame:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithCoder:) swizzledSEL:@selector(initRTLWithCoder:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setTextAlignment:) swizzledSEL:@selector(RTLSetTextAlignment:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setText:) swizzledSEL:@selector(RTLSetText:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setAttributedText:) swizzledSEL:@selector(RTLSetAttributedText:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(attributedText) swizzledSEL:@selector(RTLAttributedText) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setPlaceholder:) swizzledSEL:@selector(RTLSetPlaceholder:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setAttributedPlaceholder:) swizzledSEL:@selector(RTLSetAttributedPlaceholder:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(placeholder) swizzledSEL:@selector(RTLPlaceholder) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(attributedPlaceholder) swizzledSEL:@selector(RTLAttributedPlaceholder) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(text) swizzledSEL:@selector(RTLStrippedText) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setDelegate:) swizzledSEL:@selector(RTLSetDelegate:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(copy:) swizzledSEL:@selector(RTLCopy:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(cut:) swizzledSEL:@selector(RTLCut:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(deleteBackward) swizzledSEL:@selector(RTLDeleteBackward) isInstanceMethod:YES];  // 无参方法，签名对齐 deleteBackward
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

/// 注册文本变更通知（selector 形式注册，iOS 9+ 在 self 释放时自动移除，无需 dealloc 处理）。
/// 仅 RTL 环境注册：LTR 下回调恒为空转（RTLTextDidChange: 里 canDoRTLWork 为 NO 直接返回），不注册省去每次编辑的通知开销。
/// 注册时机是 init，不会处于 setEnableRTLCategoryWork:NO 保护窗内；语言切换走 reloadRTL 整体重建 UI，
/// 旧控件随界面销毁、新控件按新环境重新走本判断
- (void)RTLRegisterTextDidChangeNotification {
    if (![RTLTools canDoRTLWork]) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(RTLTextDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self];
}

/// 文本发生变更（用户编辑）时，使保存的原始 attributedText 失效，getter 回退到真实文本，
/// 并把存储文本归一为「RLI + 内容 + PDI」（标记被删掉则补回、位置错乱则重排），保持光标位置。
/// 注意：UITextField 仅在用户编辑时发送该通知，代码 setText:/setAttributedText: 不会触发。
- (void)RTLTextDidChange:(NSNotification *)notification {
    if (![RTLTools canDoRTLWork]) {
        return;
    }
    self.RTLOriginAttributedText = nil;
    if (self.markedTextRange) {
        // IME 组合中重排会打断输入
        return;
    }
    [self RTLNormalizeText];
}

/// 用户编辑（输入/删除/剪切/粘贴）后把存储文本重新归一为「RLI + 内容 + PDI」，并把光标位置映射回存储坐标
- (void)RTLNormalizeText {
    NSString *raw = [self RTLStrippedText];
    NSString *clean = [RTLTools removeDirectionMask:raw];
    NSString *target = clean.length ? RTL_WRAP_RTL([RTLTools rtlStringWithKeepLtrRegular:clean]) : @"";
    if ([target isEqualToString:raw]) {
        return;
    }
    // 光标：存储坐标 → 内容坐标 → 新存储坐标
    NSInteger caret = -1;
    UITextRange *selectedTextRange = self.selectedTextRange;
    if (selectedTextRange) {
        caret = [self offsetFromPosition:self.beginningOfDocument toPosition:selectedTextRange.start];
    }
    [self RTLSetText:target];  // 原始 setText:（程序化设置不触发变更通知，无重入）
    if (caret >= 0) {
        NSRange cleanCaret = [RTLTools unmaskedRangeFromMaskedRange:NSMakeRange(caret, 0) inMaskedText:raw];
        NSRange newCaret = [RTLTools maskedRangeFromUnmaskedRange:cleanCaret inMaskedText:target];
        NSUInteger location = MIN(newCaret.location, target.length);
        UITextPosition *position = [self positionFromPosition:self.beginningOfDocument offset:location];
        if (position) {
            self.selectedTextRange = [self textRangeFromPosition:position toPosition:position];
        }
    }
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

#pragma mark - text

/// UITextField 的程序化 setText: 不触发 UITextFieldTextDidChangeNotification（仅用户编辑触发），
/// 通知回调里会清 origin，这里需手动清掉保存的原始 attributedText，避免 getter 返回 stale 数据。
/// 与 UITextView 不同：field 的 textColor/font 是独立存储的属性，setText: 不会丢颜色/字体，
/// 无需构造属性串，包好方向字符后直接转调原方法。
/// （RTLSetAttributedText: 的最终赋值处于保护窗内，内部即使转调 setText: 也不会误入此分支）
- (void)RTLSetText:(NSString *)text {
    if (![RTLTools canDoRTLWork]) {
        [self RTLSetText:text];
        return;
    }
    self.RTLOriginAttributedText = nil;
    // 设置时自动带上方向字符（已带同方向包裹符号的不重复添加）；空文本不加
    if (text.length > 0 && ![RTLTools hasRTLDirectionWrap:text]) {
        text = RTL_WRAP_RTL([RTLTools rtlStringWithKeepLtrRegular:text]);
    }
    [self RTLSetText:text];
}

/// 读取时去除方向字符，外部无感；nil 保持 nil 语义
/// 非 RTL 环境存储本身无方向字符，直接走原始 getter，免去逐次扫描
- (NSString *)RTLStrippedText {
    if (![RTLTools canDoRTLWork]) {
        return [self RTLStrippedText];
    }
    NSString *origin = [self RTLStrippedText];
    return origin ? [RTLTools removeDirectionMask:origin] : origin;
}

- (NSAttributedString *)RTLAttributedText {
    if (![RTLTools canDoRTLWork]) {
        return [self RTLAttributedText];
    }
    // origin 已失效（用户编辑）或从未保存时，回退到真实存储并去除方向字符（保留属性样式）
    return self.RTLOriginAttributedText ?: [RTLTools removeDirectionMaskFromAttributedString:[self RTLAttributedText]];
}

- (void)RTLSetAttributedText:(NSAttributedString *)attributedText {
    if (!attributedText) {
        return;
    }
    if (![RTLTools canDoRTLWork]) {
        [self RTLSetAttributedText:attributedText];
        return;
    }
    if (attributedText.length == 0) {
        // 空文本不加包裹符号，直接清空（避免空内容还带方向字符）
        self.RTLOriginAttributedText = attributedText;
        [RTLTools setEnableRTLCategoryWork:NO];
        [self RTLSetAttributedText:attributedText];
        [RTLTools setEnableRTLCategoryWork:YES];
        return;
    }
    // 外面传进来的内容可能已带方向字符，保存时统一去掉（保留其余属性样式），保证 getter 返回干净内容
    self.RTLOriginAttributedText = [RTLTools removeDirectionMaskFromAttributedString:attributedText];
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
    // 已带同方向包裹符号的（如业务回设已处理文本、归一重设）不再重复添加方向符号
    NSAttributedString *finalText = newAttributeText;
    if (![RTLTools hasRTLDirectionWrap:attributedText.string]) {
        // 头部标记继承内容首字符的属性（含段落样式），避免裸插入字符抢占段落首个位置导致 alignment 失效
        NSDictionary *headAttrs = newAttributeText.length > 0 ? [RTLTools sanitizedAttributesForDirectionMark:[newAttributeText attributesAtIndex:0 effectiveRange:NULL]] : nil;
        NSAttributedString *rtlMark = [[NSAttributedString alloc] initWithString:RTLRIGHTToLEFTIsolate attributes:headAttrs];
        [newAttributeText insertAttributedString:rtlMark atIndex:0];
        // 尾部标记继承内容末字符的属性
        NSDictionary *tailAttrs = newAttributeText.length > 0 ? [RTLTools sanitizedAttributesForDirectionMark:[newAttributeText attributesAtIndex:newAttributeText.length - 1 effectiveRange:NULL]] : nil;
        NSAttributedString *rtlEndMark = [[NSAttributedString alloc] initWithString:RTLPopDirectionalIsolate attributes:tailAttrs];
        [newAttributeText appendAttributedString:rtlEndMark];
        finalText = [RTLTools rtlAttributedStringWithKeepLtrRegular:newAttributeText];
    }
    [RTLTools setEnableRTLCategoryWork:NO];
    [self RTLSetAttributedText:finalText];
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

    // 存储的 placeholder 带方向标记，读取时去除（NSString 无属性概念，边读边剥与原稿等价）；
    // 未设置/已置空时保持 nil 语义（removeDirectionMask: 会把 nil 映射成空串）
    NSString *origin = [self RTLPlaceholder];
    return origin ? [RTLTools removeDirectionMask:origin] : origin;
}

- (NSAttributedString *)RTLAttributedPlaceholder {
    if (![RTLTools canDoRTLWork]) {
        return [self RTLAttributedPlaceholder];
    }
    return self.RTLOriginAttributedPlaceholder;
}

- (void)RTLSetPlaceholder:(NSString *)placeholder {
    if (![RTLTools canDoRTLWork]) {
        [self RTLSetPlaceholder:placeholder];
        return;
    }
    if (!placeholder) {
        // 置空需同步清掉 attributedPlaceholder 的原稿缓存，避免 getter 返回 stale 数据
        // （原来这里直接 initWithString:nil 会崩溃）
        self.RTLOriginAttributedPlaceholder = nil;
        [self RTLSetPlaceholder:placeholder];
        return;
    }
    NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{}];
    self.attributedPlaceholder = attributedPlaceholder;
}

- (void)RTLSetAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder {
    if (!attributedPlaceholder) {
        return;
    }
    if (![RTLTools canDoRTLWork]) {
        [self RTLSetAttributedPlaceholder:attributedPlaceholder];
        return;
    }
    if (attributedPlaceholder.length == 0) {
        // 空文本不加包裹符号，直接清空（避免空内容还带方向字符）
        self.RTLOriginAttributedPlaceholder = attributedPlaceholder;
        [RTLTools setEnableRTLCategoryWork:NO];
        [self RTLSetAttributedPlaceholder:attributedPlaceholder];
        [RTLTools setEnableRTLCategoryWork:YES];
        return;
    }
    self.RTLOriginAttributedPlaceholder = [RTLTools removeDirectionMaskFromAttributedString:attributedPlaceholder];

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
    // 已带同方向包裹符号的不再重复添加方向符号
    NSAttributedString *finalPlaceholder = newAttributePlaceholder;
    if (![RTLTools hasRTLDirectionWrap:attributedPlaceholder.string]) {
        // 头部标记继承内容首字符的属性（含段落样式），避免裸插入字符抢占段落首个位置导致 alignment 失效
        NSDictionary *headAttrs = newAttributePlaceholder.length > 0 ? [RTLTools sanitizedAttributesForDirectionMark:[newAttributePlaceholder attributesAtIndex:0 effectiveRange:NULL]] : nil;
        NSAttributedString *rtlMark = [[NSAttributedString alloc] initWithString:RTLRIGHTToLEFTIsolate attributes:headAttrs];
        [newAttributePlaceholder insertAttributedString:rtlMark atIndex:0];
        // 尾部标记继承内容末字符的属性
        NSDictionary *tailAttrs = newAttributePlaceholder.length > 0 ? [RTLTools sanitizedAttributesForDirectionMark:[newAttributePlaceholder attributesAtIndex:newAttributePlaceholder.length - 1 effectiveRange:NULL]] : nil;
        NSAttributedString *rtlEndMark = [[NSAttributedString alloc] initWithString:RTLPopDirectionalIsolate attributes:tailAttrs];
        [newAttributePlaceholder appendAttributedString:rtlEndMark];
        finalPlaceholder = [RTLTools rtlAttributedStringWithKeepLtrRegular:newAttributePlaceholder];
    }
    [RTLTools setEnableRTLCategoryWork:NO];
    [self RTLSetAttributedPlaceholder:finalPlaceholder];
    [RTLTools setEnableRTLCategoryWork:YES];
}

#pragma mark - 系统代理拦截（range 坐标转换）

static const char RTLDelegateProxyStr = '\0';

// 注意：只拦截 setDelegate:，不拦截 delegate getter——
// UIKit 跨类读取 delegate（如键盘输入管线解析 shouldChange 回调目标）走 getter 消息，
// getter 若返回原 delegate，输入回调会绕过代理直接调外部方法（range 为带方向字符的存储坐标）。
// 不拦截时 getter 原样返回存储对象（即代理本身），代理方法会转发到原 delegate。
- (void)RTLSetDelegate:(id<UITextFieldDelegate>)delegate {
    if (![RTLTools canDoRTLWork]) {
        // 非 RTL 环境：无需坐标转换，不装代理直接透传
        [self RTLSetDelegate:delegate];
        return;
    }
    if (!delegate) {
        objc_setAssociatedObject(self, &RTLDelegateProxyStr, nil, OBJC_ASSOCIATION_RETAIN);
        [self RTLSetDelegate:nil];
        return;
    }
    RTLUITextFieldDelegateProxy *proxy = objc_getAssociatedObject(self, &RTLDelegateProxyStr);
    if (!proxy) {
        proxy = [[RTLUITextFieldDelegateProxy alloc] init];
        objc_setAssociatedObject(self, &RTLDelegateProxyStr, proxy, OBJC_ASSOCIATION_RETAIN);
    }
    proxy.target = delegate;
    // 系统 delegate 是 weak 引用，代理对象由关联对象持有
    [self RTLSetDelegate:proxy];
}

#pragma mark - 剪贴板兼容

- (void)RTLCopy:(id)sender {
    [self RTLCopy:sender];
    if ([RTLTools canDoRTLWork]) {
        [self RTLUpdatePasteboard];
    }
}

- (void)RTLCut:(id)sender {
    [self RTLCut:sender];
    if ([RTLTools canDoRTLWork]) {
        [self RTLUpdatePasteboard];
    }
}

/// 复制/剪切出去的文本不带方向字符
- (void)RTLUpdatePasteboard {
    UIPasteboard *pasteboard = UIPasteboard.generalPasteboard;
    if (pasteboard.hasStrings) {
        NSString *clean = [RTLTools removeDirectionMask:pasteboard.string];
        if (![clean isEqualToString:pasteboard.string]) {
            pasteboard.string = clean;
        }
    }
}

#pragma mark - 退格兼容

/// 光标在文本末尾（尾部 PDI 之后）时，退格删除的目标是方向标记：
/// 删掉标记 → 变更通知 → 归一化又把标记补回，可见内容永远删不掉。
/// 系统管线是先按存储坐标向代理发 shouldChange（区间为「光标前一字符」，可能是纯标记，
/// 代理侧已做同样的扩展转换，见 RTLUITextFieldDelegateProxy），批准后才调到本方法。
/// 这里把删除选区扩到「标记串 + 前一个可见字符」再精确删除，与代理转发给调用方的区间一致。
/// 注意取存储原文用 RTLStrippedText（交换后承载原始 getter），不能用 self.text（已去标记）。
- (void)RTLDeleteBackward {
    if ([RTLTools canDoRTLWork] && !self.markedTextRange) {
        UITextRange *selected = self.selectedTextRange;
        // 光标场景才处理；非空选区走原逻辑（删除后归一化兜底补回标记）
        if (selected && [selected.start isEqual:selected.end]) {
            NSUInteger caret = [self offsetFromPosition:self.beginningOfDocument toPosition:selected.end];
            NSRange backspaceRange = [RTLTools backspaceRangeForCaret:caret inMaskedText:[self RTLStrippedText] ?: @""];
            if (backspaceRange.length > 0 && !(backspaceRange.location == caret - 1 && backspaceRange.length == 1)) {
                UITextPosition *start = [self positionFromPosition:self.beginningOfDocument offset:backspaceRange.location];
                UITextPosition *end = [self positionFromPosition:self.beginningOfDocument offset:NSMaxRange(backspaceRange)];
                UITextRange *rangeToDelete = start && end ? [self textRangeFromPosition:start toPosition:end] : nil;
                if (rangeToDelete) {
                    // 不用「设选区 + 原 deleteBackward」：原实现带智能删除（会折叠待删内容前的空格），
                    // 这里用 replaceRange:withText: 精确删除。
                    // 注意：程序化 replaceRange 不会再触发 shouldChange（实测 iOS 26 模拟器），
                    // 判断已在系统调用 deleteBackward 前的 shouldChange 里完成，此处无需再询问
                    [self replaceRange:rangeToDelete withText:@""];
                    return;
                }
            }
        }
    }
    [self RTLDeleteBackward];
}

@end
