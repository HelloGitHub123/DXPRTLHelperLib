//
//  RTLConfigurationManager.h
//  Base
//
//  Created by 胡灿 on 2024/11/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTLConfigurationManager : NSObject

/// 当前语言的布局类型，从左往右 ｜ 从右往左
///
/// 默认：UISemanticContentAttributeForceLeftToRight（从左往右）
@property(nonatomic, assign) UISemanticContentAttribute currentLanSemanticStyle;

/// 需要进行反转的图片名集合
///
/// 优先级 **keepOriginImgs > needReverseImgs > needReverseImgWithRegulars**
@property(nonatomic, readonly) NSMutableSet *needReverseImgs;

/// 需要进行反转的图片名正则表达式集合
///
/// 每一个元素都应该是 "**SELF MATCHES ^1+[3578]+\\d{9}**" 的完整形式
///
/// 优先级 **keepOriginImgs > needReverseImgs > needReverseImgWithRegulars**
@property(nonatomic, readonly) NSMutableSet *needReverseImgWithRegulars;

/// 不需要进行反转的图片名集合
///
/// 优先级 **keepOriginImgs > needReverseImgs > needReverseImgWithRegulars**
@property(nonatomic, readonly) NSMutableSet<NSString *> *keepOriginImgs;

/// 始终保持LTR阅读方向的正则列表，**有序，越靠前优先级越高**
///
/// 匹配时从优先级高的开始，已被高优先级正则命中的区间，低优先级正则不再重复匹配
///
/// 每一个元素兼容 "SELF MATCHES xxx" 的谓词完整形式与直接的正则表达式
@property (nonatomic, readonly) NSMutableArray<NSString *> *keepLTRDirectionTextWithRegulars;

/// 追加保持LTR阅读方向的正则，追加的优先级低于已有元素
- (void)addKeepLTRDirectionTextWithRegulars:(NSArray<NSString *> *)regulars;

/// 插入保持LTR阅读方向的正则，插到最前，优先级高于已有元素
- (void)insertKeepLTRDirectionTextWithRegulars:(NSArray<NSString *> *)regulars;

/// 具体的语言locale
///
/// 用于配置date，默认系统第一个语言
@property(nonatomic, copy) NSString *locale;

/// 原子组件的class，用于处于hand布局
@property(nonatomic, readonly, copy) NSSet<Class> *atomViewClasses;

/// 是否启用默认行为
@property(nonatomic, assign) BOOL enableRTLCategoryWork;

+ (instancetype)sharedInstance;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
