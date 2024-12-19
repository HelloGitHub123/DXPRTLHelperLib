//
//  RTLTools.h
//  Base
//
//  Created by 胡灿 on 2024/11/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTLTools : NSObject

+ (BOOL)canDoRTLWork;

+ (void)methodSwizzlingWithClass:(Class)cls oriSEL:(SEL)oriSEL swizzledSEL:(SEL)swizzledSEL isInstanceMethod:(BOOL)isInstanceMethod;

+ (UIEdgeInsets)RTLEdgeInsetsWithInsets:(UIEdgeInsets)insets;

+ (UIRectCorner)RTLRectCornersWithCorners:(UIRectCorner)corners;

+ (BOOL)evaluateImgToReverse:(NSString *)imgName;

+ (CGRect)getFrame:(CGRect)frame withView:(UIView *)view;

+ (CGRect)getFrame:(CGRect)frame withSuperBounds:(CGRect)superBounds;

+ (BOOL)isAtomView:(UIView *)view;

+ (UISemanticContentAttribute)currentLanSemanticStyle;

+ (void)setEnableRTLCategoryWork:(BOOL)enabled;

+ (NSString *)getLocale;

@end

NS_ASSUME_NONNULL_END
