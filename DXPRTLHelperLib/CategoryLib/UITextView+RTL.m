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

#pragma mark - 系统代理拦截器

/// text 与 RTLStrippedText 交换实现后：text 选择子承载去标记逻辑（外部无感方向字符），
/// RTLStrippedText 选择子承载原始 getter（内部需要含方向字符的存储文本时调用）。
@interface UITextView (RTLInternal)
- (NSString *)RTLStrippedText;
@end

/// UITextView 系统代理拦截器：
/// 1. 带 range 的代理方法：把 range 从存储坐标转换为去除方向字符后的文本坐标后转发；
/// 2. 其余代理方法（含 UIScrollViewDelegate）：通过消息转发原样透传。
/// 代理对象由关联对象持有（系统 delegate 是 weak 引用），外部 delegate 读写无感。
@interface RTLUITextViewDelegateProxy : NSObject <UITextViewDelegate>

@property (nonatomic, weak) id<UITextViewDelegate> target;

@end

@implementation RTLUITextViewDelegateProxy

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // 存储坐标 → 干净文本坐标；替换文本同样去除方向字符
    if ([self.target respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        NSString *maskedText = textView.textStorage.string ?: @"";
        NSRange rtlRange = [RTLTools unmaskedRangeFromMaskedRange:range inMaskedText:maskedText];
        // 退格删除方向标记场景：系统按存储坐标只发「光标前一个字符」（如尾部 PDI），
        // 单删标记是视觉空操作，实际生效的删除是 RTLDeleteBackward 扩展的
        // 「标记串 + 前一个可见字符」。识别特征：转干净坐标后 length 塌缩为 0。
        // 此时按同一 backspaceRangeForCaret: 规则扩展后再转换，
        // 调用方收到的才是与删除结果一致的区间（否则拿到 length=0 的无效区间，判断必失败）
        if (text.length == 0 && range.length == 1 && rtlRange.length == 0) {
            NSRange expandedRange = [RTLTools backspaceRangeForCaret:NSMaxRange(range) inMaskedText:maskedText];
            if (expandedRange.length > 1) {
                rtlRange = [RTLTools unmaskedRangeFromMaskedRange:expandedRange inMaskedText:maskedText];
            }
        }
        NSString *cleanText = [RTLTools removeDirectionMask:text];
        return [self.target textView:textView shouldChangeTextInRange:rtlRange replacementText:cleanText];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([self.target respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:interaction:)]) {
        NSRange rtlRange = [RTLTools unmaskedRangeFromMaskedRange:characterRange inMaskedText:textView.textStorage.string ?: @""];
        return [self.target textView:textView shouldInteractWithURL:URL inRange:rtlRange interaction:interaction];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([self.target respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:interaction:)]) {
        NSRange rtlRange = [RTLTools unmaskedRangeFromMaskedRange:characterRange inMaskedText:textView.textStorage.string ?: @""];
        return [self.target textView:textView shouldInteractWithTextAttachment:textAttachment inRange:rtlRange interaction:interaction];
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

@implementation UITextView (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithFrame:) swizzledSEL:@selector(initRTLWithFrame:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithCoder:) swizzledSEL:@selector(initRTLWithCoder:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setTextAlignment:) swizzledSEL:@selector(RTLSetTextAlignment:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setText:) swizzledSEL:@selector(RTLSetText:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setAttributedText:) swizzledSEL:@selector(RTLSetAttributedText:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(attributedText) swizzledSEL:@selector(RTLAttributedText) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setTextColor:) swizzledSEL:@selector(RTLSetTextColor:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setFont:) swizzledSEL:@selector(RTLSetFont:) isInstanceMethod:YES];
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

static const char RTLLastTextColorStr = '\0';

- (UIColor *)RTLLastTextColor {
    id lastTextColor = objc_getAssociatedObject(self, &RTLLastTextColorStr);
    return lastTextColor;
}

- (void)setRTLLastTextColor:(UIColor *)lastTextColor {
    if (self.RTLLastTextColor != lastTextColor) {
        objc_setAssociatedObject(self, &RTLLastTextColorStr, lastTextColor, OBJC_ASSOCIATION_RETAIN);
    }
}

static const char RTLLastFontStr = '\0';

- (UIFont *)RTLLastFont {
    id lastFont = objc_getAssociatedObject(self, &RTLLastFontStr);
    return lastFont;
}

- (void)setRTLLastFont:(UIFont *)lastFont {
    if (self.RTLLastFont != lastFont) {
        objc_setAssociatedObject(self, &RTLLastFontStr, lastFont, OBJC_ASSOCIATION_RETAIN);
    }
}

- (instancetype)initRTLWithFrame:(CGRect)frame
{
    self = [self initRTLWithFrame:frame];
    if (self) {
        [self RTLRegisterTextDidChangeNotification];
        // 不设默认 textAlignment：对齐在 RTLSetText:/RTLSetAttributedText: 每次设值时
        // 按视图当前值构造/兜底（natural→right），创建时固定值会被内容设置旁路，
        // 且会把显式对齐烧进 typingAttributes、使空态输入失去 natural 的内容方向自适应
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
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];
}

/// 文本发生变更（用户编辑或程序化设置）时，使保存的原始 attributedText 失效，getter 回退到真实文本；
/// 用户编辑时另把存储文本归一为「RLI + 内容 + PDI」（标记被删掉则补回、位置错乱则重排），保持光标位置。
/// 注意：所有程序化设置的最终赋值均处于 setEnableRTLCategoryWork:NO 保护窗内，
/// 该通知同步触发时 canDoRTLWork 为 NO，不会误清刚保存的原始值、也不会重排。
- (void)RTLTextDidChange:(NSNotification *)notification {
    if (![RTLTools canDoRTLWork]) {
        return;
    }
    self.RTLOriginAttributedText = nil;
    if (self.markedTextRange) {
        // IME 组合中重排会打断输入
        return;
    }
    [self RTLNormalizeTextStorage];
}

/// 用户编辑（输入/删除/剪切/粘贴）后把存储文本重新归一为「RLI + 内容 + PDI」，并把光标位置映射回存储坐标。
/// 归一结果基于现有 textStorage 的属性直接构建（属性已是 RTL 处理后的最终形态），
/// 窗口内走原始 setAttributedText:，避免 RTLSetAttributedText: 对对齐方式的二次翻转。
- (void)RTLNormalizeTextStorage {
    NSAttributedString *rawAttr = [self.textStorage copy];
    NSString *raw = rawAttr.string;
    NSString *clean = [RTLTools removeDirectionMask:raw];
    if (clean.length == 0) {
        if (raw.length == 0) {
            return;
        }
        // 只剩方向字符的残留（比如全选删除），直接清空，避免空内容还带标记
        [RTLTools setEnableRTLCategoryWork:NO];
        [self RTLSetAttributedText:[[NSAttributedString alloc] initWithString:@""]];
        [RTLTools setEnableRTLCategoryWork:YES];
        return;
    }
    // 去掉标记、保留属性的内容，重新包裹（标记继承首末字符属性，与 RTLSetAttributedText: 一致）
    NSAttributedString *cleanAttr = [RTLTools removeDirectionMaskFromAttributedString:rawAttr];
    NSMutableAttributedString *target = [[NSMutableAttributedString alloc] initWithString:RTLRIGHTToLEFTIsolate
                                                                              attributes:[RTLTools sanitizedAttributesForDirectionMark:[cleanAttr attributesAtIndex:0 effectiveRange:NULL]]];
    [target appendAttributedString:cleanAttr];
    [target appendAttributedString:[[NSAttributedString alloc] initWithString:RTLPopDirectionalIsolate
                                                                    attributes:[RTLTools sanitizedAttributesForDirectionMark:[cleanAttr attributesAtIndex:cleanAttr.length - 1 effectiveRange:NULL]]]];
    NSAttributedString *finalAttr = [RTLTools rtlAttributedStringWithKeepLtrRegular:target];
    if ([finalAttr.string isEqualToString:raw]) {
        return;
    }
    NSRange cleanSel = [RTLTools unmaskedRangeFromMaskedRange:self.selectedRange inMaskedText:raw];
    [RTLTools setEnableRTLCategoryWork:NO];
    [self RTLSetAttributedText:finalAttr];
    [RTLTools setEnableRTLCategoryWork:YES];
    NSRange newSel = [RTLTools maskedRangeFromUnmaskedRange:cleanSel inMaskedText:self.textStorage.string];
    if (newSel.location > self.textStorage.length) {
        newSel.location = self.textStorage.length;
    }
    self.selectedRange = newSel;
}

/// UITextView 的 textColor/font getter 从 textStorage/typingAttributes 派生（非独立存储），
/// 裸 attributedText 会把它们连同 typingAttributes 一起冲成 nil，视图自身不再记得业务设过的值。
/// 这里记住最后一次显式设置的值，供 RTLSetText: 在 getter 失效时兜底。
/// （已验证 setText:/setAttributedText: 内部不会转调这两个 setter，不会误记内部派生值）
- (void)RTLSetTextColor:(UIColor *)textColor {
    // 非 RTL 环境无需记录（记录只为 RTL 设值路径兜底）
    if ([RTLTools canDoRTLWork] && textColor) {
        self.RTLLastTextColor = textColor;
    }
    [self RTLSetTextColor:textColor];
}

- (void)RTLSetFont:(UIFont *)font {
    if ([RTLTools canDoRTLWork] && font) {
        self.RTLLastFont = font;
    }
    [self RTLSetFont:font];
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

#pragma mark - text

- (void)RTLSetText:(NSString *)text {
    if (![RTLTools canDoRTLWork]) {
        [self RTLSetText:text];
        return;
    }
    // 设置时自动带上方向字符（已带同方向包裹符号的不重复添加）；空文本不加
    NSString *wrapped = text;
    if (text.length > 0 && ![RTLTools hasRTLDirectionWrap:text]) {
        wrapped = RTL_WRAP_RTL([RTLTools rtlStringWithKeepLtrRegular:text]);
    }
    // UITextView 的 setText: 内部用 typingAttributes 构造字符串，但 typingAttributes
    // 会被之前的 setAttributedText: 覆盖（与 textColor/font 属性脱钩），颜色/字体不确定；
    // 这里显式构造（属性直接取视图当前值）后，窗口内直接走原始 setAttributedText:：
    // 1. 构造的对齐是视图当前值（已是 RTL 坐标），不能再走 RTLSetAttributedText: 的翻转逻辑；
    // 2. 窗口使变更通知跳过，避免误清刚保存的原始值。
    // textColor/font getter 已被裸 attributedText 冲成 nil 时，用记住的最近一次显式设置值兜底。
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    UIFont *font = self.font ?: self.RTLLastFont;
    if (font) {
        attrs[NSFontAttributeName] = font;
    }
    UIColor *textColor = self.textColor ?: self.RTLLastTextColor;
    if (textColor) {
        attrs[NSForegroundColorAttributeName] = textColor;
    }
    NSMutableParagraphStyle *para = [NSMutableParagraphStyle new];
    para.alignment = self.textAlignment == NSTextAlignmentNatural ? NSTextAlignmentRight : self.textAlignment;
    attrs[NSParagraphStyleAttributeName] = para;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:wrapped ?: @"" attributes:attrs];
    self.RTLOriginAttributedText = [RTLTools removeDirectionMaskFromAttributedString:attributedText];
    [RTLTools setEnableRTLCategoryWork:NO];
    [self RTLSetAttributedText:attributedText];
    [RTLTools setEnableRTLCategoryWork:YES];
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
    // 视图当前的 textAlignment 已经过 RTL 翻转（RTL 坐标），无段落样式、或段落样式未显式设置对齐（natural）
    // 的区间用它兜底，避免业务只传字体颜色/行距等时对齐方式丢失（走 natural 解析，Center 等显式对齐会失效）
    NSTextAlignment viewAlignment = self.textAlignment == NSTextAlignmentNatural ? NSTextAlignmentRight : self.textAlignment;
    [attributedText enumerateAttributesInRange:attrsRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        NSMutableParagraphStyle *para = [[attrs valueForKey:NSParagraphStyleAttributeName] mutableCopy];
        NSMutableDictionary *newAttrs = [attrs mutableCopy];
        if (para && para.alignment == NSTextAlignmentNatural && viewAlignment != NSTextAlignmentNatural) {
            // 段落样式存在但没有显式对齐（natural）：视图对齐已是 RTL 坐标，直接使用，不再翻转
            para.alignment = viewAlignment;
        } else if (para) {
            // 段落样式里的显式对齐是业务的设计时意图（LTR 坐标），需要翻转
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
        } else if (viewAlignment != NSTextAlignmentNatural) {
            // 无段落样式：同样用视图对齐兜底
            para = [[NSMutableParagraphStyle alloc] init];
            para.alignment = viewAlignment;
        }
        if (para) {
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

#pragma mark - 选中区域（干净文本坐标）

- (NSRange)RTLSelectedRange {
    return [RTLTools unmaskedRangeFromMaskedRange:self.selectedRange inMaskedText:self.textStorage.string ?: @""];
}

- (void)setRTLSelectedRange:(NSRange)range {
    self.selectedRange = [RTLTools maskedRangeFromUnmaskedRange:range inMaskedText:self.textStorage.string ?: @""];
}

#pragma mark - 系统代理拦截（range 坐标转换）

static const char RTLDelegateProxyStr = '\0';

// 注意：只拦截 setDelegate:，不拦截 delegate getter——
// UIKit 跨类读取 delegate（如键盘输入管线解析 shouldChange 回调目标）走 getter 消息，
// getter 若返回原 delegate，输入回调会绕过代理直接调外部方法（range 为带方向字符的存储坐标）。
// 不拦截时 getter 原样返回存储对象（即代理本身），代理方法会转发到原 delegate。
- (void)RTLSetDelegate:(id<UITextViewDelegate>)delegate {
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
    RTLUITextViewDelegateProxy *proxy = objc_getAssociatedObject(self, &RTLDelegateProxyStr);
    if (!proxy) {
        proxy = [[RTLUITextViewDelegateProxy alloc] init];
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
/// 代理侧已做同样的扩展转换，见 RTLUITextViewDelegateProxy），批准后才调到本方法。
/// 这里把删除选区扩到「标记串 + 前一个可见字符」再精确删除，与代理转发给调用方的区间一致。
- (void)RTLDeleteBackward {
    if ([RTLTools canDoRTLWork] && !self.markedTextRange) {
        UITextRange *selected = self.selectedTextRange;
        // 光标场景才处理；非空选区走原逻辑（删除后归一化兜底补回标记）
        if (selected && [selected.start isEqual:selected.end]) {
            NSUInteger caret = [self offsetFromPosition:self.beginningOfDocument toPosition:selected.end];
            NSRange backspaceRange = [RTLTools backspaceRangeForCaret:caret inMaskedText:self.textStorage.string ?: @""];
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
