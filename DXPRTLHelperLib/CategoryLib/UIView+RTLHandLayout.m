//
//  UIView+RTLHandLayout.m
//  Base
//
//  Created by 胡灿 on 2024/11/19.
//

#import "UIView+RTLHandLayout.h"
#import <objc/runtime.h>
#import "RTLTools.h"

@implementation UIView (RTLHandLayout)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(setFrame:) swizzledSEL:@selector(RTLSetFrame:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(addSubview:) swizzledSEL:@selector(RTLAddSubview:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(insertSubview:atIndex:) swizzledSEL:@selector(RTLInsertSubview:atIndex:) isInstanceMethod:YES];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(removeFromSuperview) swizzledSEL:@selector(RTLRemoveFromSuperview) isInstanceMethod:YES];
    });
}

- (void)RTLSetFrame:(CGRect)frame {
    // 1. 调整自己的frame
    // 2. 调整子view的frame
    if (([self.superview class].rtl_layoutStyle == RTLLayoutStyleHand || self.superview.rtl_layoutStyle == RTLLayoutStyleHand) && [RTLTools canDoRTLWork]) {
        // 调整自己frame
        frame = [RTLTools getFrame:frame withView:self];
        // 只有width变了才需要修改subview的frame
        if (([self class].rtl_layoutStyle == RTLLayoutStyleHand || self.rtl_layoutStyle == RTLLayoutStyleHand) && self.frame.size.width != frame.size.width && ![RTLTools isAtomView:self]) {
            // 调整子view 不会递归 因为调整子view的frame并不会改变其width
            for (UIView *subview in self.subviews) {
                CGRect originSubFrame = [RTLTools getFrame:subview.frame withView:subview];  // 获取原始frame
                [subview RTLSetFrame:[RTLTools getFrame:originSubFrame withSuperBounds:frame]];  // 设置适配的frame
            }
        }
    }
    [self RTLSetFrame:frame];
}

- (void)RTLAddSubview:(UIView *)view {
    // 1. 添加view
    // 2. 根据当前self的rtl_layoutStyle设置view的rtl_layoutStyle 会递归且调整view的子view的rtl_layoutStyle
    // 3. 根据当前self的rtl_layoutStyle设置view的frame
    BOOL hasBeenSubView = [view isDescendantOfView:self];
    [self RTLAddSubview:view];
    // 真正加入subview
    if (!hasBeenSubView && [RTLTools canDoRTLWork]) {
        if (([self class].rtl_layoutStyle == RTLLayoutStyleHand || self.rtl_layoutStyle == RTLLayoutStyleHand) && ![RTLTools isAtomView:self] && ([view class].rtl_layoutStyle == RTLLayoutStyleUnset && view.rtl_layoutStyle == RTLLayoutStyleUnset)) {
            // 将view标记为手动布局 会递归
            // 同时会调整view的子view的frame
            view.rtl_layoutStyle = RTLLayoutStyleHand;
            // view适配frame
            // view 被加入之前设置frame 会适配frame
            // view 被加入之前没有设置frame(默认zero) 该方法不会适配frame
            [view RTLSetFrame:[RTLTools getFrame:view.frame withView:view]];
        }
    }
}

- (void)RTLInsertSubview:(UIView *)view atIndex:(NSInteger)index {
    // UITableView添加cell时会走
    BOOL hasBeenSubView = [view isDescendantOfView:self];
    [self RTLInsertSubview:view atIndex:index];
    if (!hasBeenSubView && [RTLTools canDoRTLWork]) {
        if (([self class].rtl_layoutStyle == RTLLayoutStyleHand || self.rtl_layoutStyle == RTLLayoutStyleHand) && ![RTLTools isAtomView:self] && ([view class].rtl_layoutStyle == RTLLayoutStyleUnset && view.rtl_layoutStyle == RTLLayoutStyleUnset)) {
            // 将view标记为手动布局 会递归
            // 同时会调整view的子view的frame
            view.rtl_layoutStyle = RTLLayoutStyleHand;
            // view适配frame
            // view 被加入之前设置frame 会适配frame
            // view 被加入之前没有设置frame(默认zero) 该方法不会适配frame
            [view RTLSetFrame:[RTLTools getFrame:view.frame withView:view]];
        }
    }
}

- (void)removeHnadLayoutFromSuperview {
    // 父view是RTLLayoutStyleHand 子view的class是RTLLayoutStyleUnset 子view的rtl_layoutStyle是RTLLayoutStyleHand
    // 针对被强行设置成RTLLayoutStyleHand的子view 移除适配rtl的frame效果
    if ([self class].rtl_layoutStyle == RTLLayoutStyleUnset && self.rtl_layoutStyle == RTLLayoutStyleHand) {
        if ([RTLTools canDoRTLWork] && self.superview.rtl_layoutStyle == RTLLayoutStyleHand) [self RTLSetFrame:[RTLTools getFrame:self.frame withView:self.superview]];
        // 本身不是hand布局 但是由于加入hand布局的父容器 被修改成了hand布局
        for (UIView *subview in self.subviews) {
            [subview removeFromSuperview];
        }
        // 一定要放在便利子view之后
        self.rtl_layoutStyle = RTLLayoutStyleUnset;
    }
}

- (void)RTLRemoveFromSuperview {
    [self removeHnadLayoutFromSuperview];  // 取消hand标志 还原初始化时的布局
    [self RTLRemoveFromSuperview];
}

#pragma mark -- rtl_layoutStyle

// class.rtl_layoutStyle = RTLLayoutStyleAuto 说明 self.rtl_layoutStyle 只能设置成 RTLLayoutStyleAuto， 一般不会直接设置self.rtl_layoutStyle，直接通过class.rtl_layoutStyle 来判断
// class.rtl_layoutStyle = RTLLayoutStyleHand 说明 self.rtl_layoutStyle 只能设置成 RTLLayoutStyleHand， 一般不会直接设置self.rtl_layoutStyle，直接通过class.rtl_layoutStyle 来判断。一般需要设置class.rtl_layoutStyle来说明是hand布局
// class.rtl_layoutStyle = RTLLayoutStyleUnset 说明 self.rtl_layoutStyle 可以被任意设置，一般用于hand布局中将子view也设置成hand布局的默认行为

static const char rtlLayoutStyle = '\0';
- (void)setRtl_layoutStyle:(RTLLayoutStyle)rtl_layoutStyle {
    // 只有 class.rtl_layoutStyle == RTLLayoutStyleUnset 才会去设置 self.rtl_layoutStyle
    // class.rtl_layoutStyle 是一个view类的布局类型，self.rtl_layoutStyle 是为了适配hand布局里面子view的布局。默认认为hand布局的view里面所有子view的布局也是hand布局，此时会将子view(class.rtl_layoutStyle = RTLLayoutStyleUnset 说明view.rtl_layoutStyle可以被修改)的rtl_layoutStyle设置为RTLLayoutStyleHand，但是不会修改其class.rtl_layoutStyle
    // 如果class.rtl_layoutStyle = RTLLayoutStyleAuto 说明此时是为了适配hand布局里面使用的auto布局的view 通常无需手动设置
    if ([self class].rtl_layoutStyle == RTLLayoutStyleUnset && rtl_layoutStyle != self.rtl_layoutStyle) {
        // 非atomView对其子view也设置相同的rtl_layoutStyle
        // atomView无需标记
        if (![RTLTools isAtomView:self]) {
            objc_setAssociatedObject(self, &rtlLayoutStyle, [NSNumber numberWithInteger:rtl_layoutStyle], OBJC_ASSOCIATION_RETAIN);
            for (UIView *subview in self.subviews) {
                if (rtl_layoutStyle == RTLLayoutStyleHand) {
                    // subview 没有设置 rtl_layoutStyle 才递归
                    if (subview.rtl_layoutStyle == RTLLayoutStyleUnset) {
                        subview.rtl_layoutStyle = rtl_layoutStyle;
                    }
                    if ([RTLTools canDoRTLWork]) [subview RTLSetFrame:[RTLTools getFrame:subview.frame withView:subview]];
                } else if (rtl_layoutStyle == RTLLayoutStyleAuto) {
                    
                } else if (rtl_layoutStyle == RTLLayoutStyleUnset) {
                    
                }
            }
        }
    }
}

- (RTLLayoutStyle)rtl_layoutStyle {
    id rtl_layoutStyle = objc_getAssociatedObject(self, &rtlLayoutStyle);
    if (!rtl_layoutStyle) {
        objc_setAssociatedObject(self, &rtlLayoutStyle, [NSNumber numberWithInteger:RTLLayoutStyleUnset], OBJC_ASSOCIATION_RETAIN);
        return RTLLayoutStyleUnset;
    }
    NSNumber *num = objc_getAssociatedObject(self, &rtlLayoutStyle);
    return [num integerValue];
}

static const char rtlClassLayoutStyle = '\0';
+ (void)setRtl_layoutStyle:(RTLLayoutStyle)rtl_layoutStyle {
    if (rtl_layoutStyle != self.rtl_layoutStyle) {
        objc_setAssociatedObject(self, &rtlClassLayoutStyle, [NSNumber numberWithInteger:rtl_layoutStyle], OBJC_ASSOCIATION_RETAIN);
    }
}

+ (RTLLayoutStyle)rtl_layoutStyle {
    id rtl_layoutStyle = objc_getAssociatedObject(self, &rtlClassLayoutStyle);
    if (!rtl_layoutStyle) {
        objc_setAssociatedObject(self, &rtlClassLayoutStyle, [NSNumber numberWithInteger:RTLLayoutStyleUnset], OBJC_ASSOCIATION_RETAIN);
        return RTLLayoutStyleUnset;
    }
    NSNumber *num = objc_getAssociatedObject(self, &rtlClassLayoutStyle);
    return [num integerValue];
}

@end

// 设置vc.view.rtl_layoutStyle
@implementation UIViewController (RTLHandLayout)

static const char rtlVCLayoutStyle = '\0';
- (void)setRtl_layoutStyle:(RTLLayoutStyle)rtl_layoutStyle {
    if (rtl_layoutStyle != self.rtl_layoutStyle) {
        objc_setAssociatedObject(self, &rtlVCLayoutStyle, [NSNumber numberWithInteger:rtl_layoutStyle], OBJC_ASSOCIATION_RETAIN);
        if ([self class].rtl_layoutStyle == RTLLayoutStyleUnset) self.view.rtl_layoutStyle = rtl_layoutStyle;
    }
}

- (RTLLayoutStyle)rtl_layoutStyle {
    id rtl_layoutStyle = objc_getAssociatedObject(self, &rtlVCLayoutStyle);
    if (!rtl_layoutStyle) {
        objc_setAssociatedObject(self, &rtlVCLayoutStyle, [NSNumber numberWithInteger:RTLLayoutStyleUnset], OBJC_ASSOCIATION_RETAIN);
        return RTLLayoutStyleUnset;
    }
    NSNumber *num = objc_getAssociatedObject(self, &rtlVCLayoutStyle);
    return [num integerValue];
}

static const char rtlVCClassLayoutStyle = '\0';
+ (void)setRtl_layoutStyle:(RTLLayoutStyle)rtl_layoutStyle {
    if (rtl_layoutStyle != self.rtl_layoutStyle) {
        objc_setAssociatedObject(self, &rtlVCClassLayoutStyle, [NSNumber numberWithInteger:rtl_layoutStyle], OBJC_ASSOCIATION_RETAIN);
        // 只需要执行一次
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            SEL methodSel = @selector(viewDidLoad);
            Method method = class_getInstanceMethod(self, methodSel);
            IMP methodImp = method_getImplementation(method);
            const char *methodType = method_getTypeEncoding(method);
            id (*methodBlock)(id, SEL) = (void *)methodImp;
            __weak __block typeof(self) weakSelf = self;
            IMP rtlMethodImp = imp_implementationWithBlock(^(UIViewController *obj){
                methodBlock(obj, methodSel);
                if ([RTLTools canDoRTLWork] && weakSelf.rtl_layoutStyle == RTLLayoutStyleHand) {
                    obj.view.rtl_layoutStyle = RTLLayoutStyleHand;
                }
            });
            class_replaceMethod(self, methodSel, rtlMethodImp, methodType);
        });
    }
}

+ (RTLLayoutStyle)rtl_layoutStyle {
    id rtl_layoutStyle = objc_getAssociatedObject(self, &rtlVCClassLayoutStyle);
    if (!rtl_layoutStyle) {
        objc_setAssociatedObject(self, &rtlVCClassLayoutStyle, [NSNumber numberWithInteger:RTLLayoutStyleUnset], OBJC_ASSOCIATION_RETAIN);
        return RTLLayoutStyleUnset;
    }
    NSNumber *num = objc_getAssociatedObject(self, &rtlVCClassLayoutStyle);
    return [num integerValue];
}

@end
