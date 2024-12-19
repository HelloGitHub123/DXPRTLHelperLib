//
//  UIBezierPath+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/13.
//

#import "UIBezierPath+RTL.h"
#import "RTLTools.h"

@implementation UIBezierPath (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(bezierPathWithRoundedRect:byRoundingCorners:cornerRadii:) swizzledSEL:@selector(RTLBezierPathWithRoundedRect:byRoundingCorners:cornerRadii:) isInstanceMethod:NO];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(bezierPathWithArcCenter:radius:startAngle:endAngle:clockwise:) swizzledSEL:@selector(RTLBezierPathWithArcCenter:radius:startAngle:endAngle:clockwise:) isInstanceMethod:NO];
    });
}

+ (instancetype)RTLBezierPathWithRoundedRect:(CGRect)rect byRoundingCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii {
    if (corners && [RTLTools canDoRTLWork]) {
        corners = [RTLTools RTLRectCornersWithCorners:corners];
    }
    return [self RTLBezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:cornerRadii];
}

+ (instancetype)RTLBezierPathWithArcCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle clockwise:(BOOL)clockwise {
    if ([RTLTools canDoRTLWork]) {
        return [self RTLBezierPathWithArcCenter:center radius:radius startAngle:endAngle endAngle:startAngle clockwise:!clockwise];
    }
    return [self RTLBezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:clockwise];
}

@end
