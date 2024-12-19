//
//  RTLHelper.h
//  FDFullScreenPopGestureDemo
//
//  Created by cs on 2018/10/20.
//  Copyright © 2018 cs. All rights reserved.
//

#import <Foundation/Foundation.h>

// RTLBlock 中应该包含 是rtl的情况 和 非rtl的情况 的代码
typedef void (^RTLBlock)(BOOL isRTL);

NS_ASSUME_NONNULL_BEGIN

/// 用于适配RTL的工具
@interface RTLHelper : NSObject

// 我们的配置可能和rtl的Category的适配操作有冲突 冲突可以在
// doRTLBlock:enableCategoryWork:中进行解决 这个方法添加的rtlblock不会受到rtl的Category影响

// 当前UI的布局类型 从左往右 ｜ 从右往左 默认：UISemanticContentAttributeForceLeftToRight
//@property (nonatomic, assign) UISemanticContentAttribute currentUISemanticStyle;

/// 当前语言的布局类型，从左往右 ｜ 从右往左
///
/// 默认：UISemanticContentAttributeForceLeftToRight（从左往右）
@property (nonatomic, assign) UISemanticContentAttribute currentLanSemanticStyle;

/// 需要进行反转的图片名集合
///
/// 优先级 **keepOriginImgs > needReverseImgs > needReverseImgWithRegulars**
@property (nonatomic, strong, readonly) NSMutableSet<NSString *> *needReverseImgs;

/// 需要进行反转的图片名正则表达式集合
///
/// 每一个元素都应该是 "**SELF MATCHES ^1+[3578]+\\d{9}**" 的完整形式
///
/// 优先级 **keepOriginImgs > needReverseImgs > needReverseImgWithRegulars**
@property (nonatomic, strong, readonly) NSMutableSet<NSString *> *needReverseImgWithRegulars;

/// 不需要进行反转的图片名集合
///
/// 优先级 **keepOriginImgs > needReverseImgs > needReverseImgWithRegulars**
@property (nonatomic, strong, readonly) NSMutableSet<NSString *> *keepOriginImgs;

/// 具体的语言locale
///
/// 用于配置date，默认系统第一个语言
@property (nonatomic, copy) NSString *locale;

/// singleton instance
///
/// 可以直接使用RTLHelper.sharedInstance获取单例，Objective-C中的从class属性是从Xcode 8开始引入的，并且理论上可以在iOS 7及更高版本的设备上运行，从ios9.0开始适配rtl
@property (nonatomic, readonly, class) RTLHelper *sharedInstance API_AVAILABLE(ios(9.0));

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 从ios9.0开始适配rtl
+ (instancetype)sharedInstance API_AVAILABLE(ios(9.0));

/// 使用RTLBlock进行RTL适配
///
/// RTLBlock中应该包含非RTL环境的代码和RTL环境的代码。
///
/// 如：
///
/// ```objc
/// [[RTLHelper sharedInstance] doRTLBlock:^(BOOL isRTL) {
///     if (isRTL) {
///         // do something to adjust the RTL environment.
///     } else {
///         // do something to adjust the LTR environment.
///     }
/// } enableCategoryWork:YES];
/// ```
///
/// - Parameters:
///   - rtlBlock: 进行RTL适配的block，带有isRTL标识
///   - enableCategoryWork: 是否使用RTLHelper的默认行为，默认行为不是想要的结果的时候可用，一般用于处理默认行为的bug
- (void)doRTLBlock:(RTLBlock)rtlBlock enableCategoryWork:(BOOL)enableCategoryWork;

/// 使用RTLBlock进行RTL适配
///
/// RTLBlock中应该包含非RTL环境的代码和RTL环境的代码。默认使用RTLHelper的默认行为，若要不使用RTLHelper默认行为，请使用**doRTLBlock:enableCategoryWork:**
///
/// 如：
///
/// ```objc
/// [[RTLHelper sharedInstance] doRTLBlock:^(BOOL isRTL) {
///     if (isRTL) {
///         // do something to adjust the RTL environment.
///     } else {
///         // do something to adjust the LTR environment.
///     }
/// }];
/// ```
/// - Parameter rtlBlock: 进行RTL适配的block，带有isRTL标识
- (void)doRTLBlock:(RTLBlock)rtlBlock;

/// 根据网络图片url判断是否反转图片
///
///由于加载网络图片无法内部直接判断，所以交给外部处理。一般需要外部自己使用runtime交换方法在原来的加载网络图片的方法之上使用此方法。url 会使用 keepOriginImgs，needReverseImgs 和 needReverseImgWithRegulars 规则来判断
/// - Parameters:
///   - url: 网络图片的url，可以为nil，为nil时不会反转
///   - image: 需要反转的UIImage
- (UIImage *)reverseImgFilterWithUrl:(NSString * _Nullable)url image:(UIImage *)image;

/// RTL反转图片，用于从NSData中读取图片的特殊情况
///
/// 直接反转图片，不会使用 keepOriginImgs，needReverseImgs 和 needReverseImgWithRegulars 规则来判断
/// - Parameter image: 需要反转的UIImage
- (UIImage *)reverseImgWithImage:(UIImage *)image;

/// UIView 适配 RTL
///
/// - 使用时需要在superView存在且其frame确定的情况下有效
/// - 当使用leading和trailing设置好约束系统在autolayout时会计算并设置frame，此时frame是适配rtl的，但是如果此时对frame进行反转的话，会导致rtl适配失效
/// > Warning: 纯frame布局已经在内部实现,可以直接使用 顶层(view|VC).rtl_layoutStyle = RTLLayoutStyleHand 或 顶层(view|VC)类名.rtl_layoutStyle = RTLLayoutStyleHand 来实现
///
/// > Note: 该方法可以用于第三方sdk中临时的纯frame布局的UIView适配：runtime+该方法。
/// - Parameters:
///   - frame: 要适配的view的frame
///   - view: 要适配的view
- (void)setFrame:(CGRect)frame withView:(UIView *)view;

/// UIView 适配 RTL
///
/// 只会递归适配非atomView，不会对atomView的子view进行适配。
/// - 该方法需要在superView存在且其frame确定的情况下有效；
/// - 当使用leading和trailing设置好约束系统在autolayout时会计算并设置frame，此时frame是适配rtl的，但是如果此时对frame进行反转的话，会导致rtl适配失效
///
/// ### AtomView
///
/// ```objc
/// @[
///     [UIButton class],
///     [UISlider class],
///     [UISegmentedControl class],
///     [UISwitch class],
///     [UIProgressView class],
///     [UIPageControl class],
///     [UIDatePicker class],
///     [UITextField class],
///     [UITextView class],
///     [UISearchBar class],
///     [UIAlertView class],
/// ]
/// ```
///
/// > Warning: 纯frame布局已经在内部实现,可以直接使用 顶层(view|VC).rtl_layoutStyle = RTLLayoutStyleHand 或 顶层(view|VC)类名.rtl_layoutStyle = RTLLayoutStyleHand 来实现
///
/// > Note: 该方法可以用于第三方sdk中临时的纯frame布局的UIView适配：runtime+该方法。
/// - Parameters:
///   - frame: 要适配的view的frame
///   - view: 要适配的view
///   - enableSubviews: 是否递归适配子view
- (void)setFrame:(CGRect)frame withView:(UIView *)view enableSubviews:(BOOL)enableSubviews;

/// CALayer 递归适配 RTL
///
/// 不会递归适配子layer
/// - Parameters:
///   - frame: 要适配的layer的frame
///   - layer: 要适配的layer
- (void)setFrame:(CGRect)frame withLayer:(CALayer *)layer;

/// CALayer 递归适配 RTL
///
/// CALayer 的布局适配内部没有实现
/// - Parameters:
///   - frame: 要适配的layer的frame
///   - layer: 要适配的layer
///   - enableSublayers: 是否递归适配子layer
- (void)setFrame:(CGRect)frame withLayer:(CALayer *)layer enableSublayers:(BOOL)enableSublayers;  // 适配子layer


/// 处理 rtl 语言 和 ltr 语言 混合的情况，内部不做处理，外部使用该方法处理字符串
///
/// 防止文本第一个字符不是从右往左的语言而导致误判
/// - Parameter string: 要适配RTL的字符串
- (NSString *)RTLString:(NSString *)string;

/// 类适配RTL布局
///
/// 设置某纯frame布局的类的rtl_layoutStyle属性为RTLLayoutStyleHand。同 类名.rtl_layoutStyle = RTLLayoutStyleHand; 效果一样。区别在于使用该方法不用导入该类的头文件，而是直接通过类名字符串来设置，如果该类不存在或者无rtl_layoutStyle属性，则不会去设置rtl_layoutStyle，进而不会适配rtl。可以设置 rtl_layoutStyle 属性的类应该是 UIView子类 和 UIViewController 子类
/// - Parameter clsToken: 类名
- (void)enableHandLayoutClassWithToken:(NSString *)clsToken;

/// 类适配RTL布局
///
/// 设置clsTokens数组中clsToken对应的纯frame布局的类的rtl_layoutStyle属性为RTLLayoutStyleHand；
/// 内部调用enableHandLayoutClassWithToken:实现
/// - Parameter clsTokens: 类名数组
- (void)enableHandLayoutClassWithTokens:(NSArray<NSString *> *)clsTokens;

// rtl 内置的交换方法的方法 主要用于第三方库的处理


/**
 class_getInstanceMethod实际上就是调用了runtime里写的IMP lookUpImpOrNil(Class cls, SEL sel, id inst, bool initialize, bool cache, bool resolver)函数，这个函数作用是在给定类的方法列表和方法cache列表中查找给定的方法的实现。
 这个方法会在以此从此类的cache和方法列表中查找这个方法的实现，一旦找到就存储在cache中并返回
 也就说这个方法获取到的方法实现可能会是父类甚至是父类的父类的方法实现
 同样的，在方法调用的时候，一样会首先执行这个查找方法。当你的子类和父类用一个同名的方法对另一个同名的方法进行交换之后，调用子类的那个方法时，就会出现循环调用的问题，最终导致程序crash。
 因此，在具有继承关系时，对同一个方法进行方法交换时，一定要将子类自定义的方法的名字和父类不一样才行，不然一定会出现魂环调用的问题
 */

/// 替换类的类方法
/// @param cls 要修改的类的类对象
/// @param originalSelector 要替换的方法
/// @param swizzledSelector 新的方法实现
- (void)swizzleClassMethodWithCls:(Class)cls oriSel:(SEL)originalSelector swiSel:(SEL)swizzledSelector;

/// 替换类的对象方法
/// @param cls 要修改的类的类对象
/// @param originalSelector 要替换的方法
/// @param swizzledSelector 新的方法实现
- (void)swizzleInstanceMethodWithCls:(Class)cls oriSel:(SEL)originalSelector swiSel:(SEL)swizzledSelector;

/// 交换不同类中两个对象方法
///
/// 自定义的方法可以写在任何的自定义类中
/// @param originalCls 被交换的类的类对象
/// @param swizzledCls 用来交换的类的类对象
/// @param originalSelector 被交换的方法
/// @param swizzledSelector 用来交换的方法
- (void)swizzleDifferentClassInstanceMethodWithOriCls:(Class)originalCls swiCls:(Class)swizzledCls oriSel:(SEL)originalSelector swiSel:(SEL)swizzledSelector;

/// 交换不同类中两个类方法
///
/// 自定义的方法可以写在任何的自定义类中
/// @param originalCls 被交换的类的类对象
/// @param swizzledCls 用来交换的类的类对象
/// @param originalSelector 被交换的方法
/// @param swizzledSelector 用来交换的方法
- (void)swizzleDifferentClassClassMethodWithOriCls:(Class)originalCls swiCls:(Class)swizzledCls oriSel:(SEL)originalSelector swiSel:(SEL)swizzledSelector;

@end

NS_ASSUME_NONNULL_END
