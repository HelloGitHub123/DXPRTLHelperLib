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
