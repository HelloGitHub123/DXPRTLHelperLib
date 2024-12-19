//
//  UIView+RTLHandLayout.h
//  Base
//
//  Created by 胡灿 on 2024/11/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RTLLayoutStyle) {
    RTLLayoutStyleHand,
    RTLLayoutStyleAuto,
    RTLLayoutStyleUnset,
};

@interface UIView (RTLHandLayout)

@property (nonatomic, assign, class) RTLLayoutStyle rtl_layoutStyle;
@property (nonatomic, assign) RTLLayoutStyle rtl_layoutStyle;

@end

@interface UIViewController (RTLHandLayout)

@property (nonatomic, assign, class) RTLLayoutStyle rtl_layoutStyle;
@property (nonatomic, assign) RTLLayoutStyle rtl_layoutStyle;

@end

NS_ASSUME_NONNULL_END
