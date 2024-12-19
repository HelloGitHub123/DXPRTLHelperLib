//
//  UIImage+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/4.
//

#import "UIImage+RTL.h"
#import "RTLTools.h"

@implementation UIImage (RTL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(imageNamed:) swizzledSEL:@selector(RTLImageNamed:) isInstanceMethod:NO];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(imageWithContentsOfFile:) swizzledSEL:@selector(RTLImageWithContentsOfFile:) isInstanceMethod:NO];
        [RTLTools methodSwizzlingWithClass:self oriSEL:@selector(initWithContentsOfFile:) swizzledSEL:@selector(initRTLWithContentsOfFile:) isInstanceMethod:YES];
    });
}

+ (UIImage *)RTLImageNamed:(NSString *)name {
    UIImage *img = [self RTLImageNamed:name];
    if (img && [RTLTools canDoRTLWork] && [RTLTools evaluateImgToReverse:name]) {
        img = [UIImage imageWithCGImage:img.CGImage
                                  scale:img.scale
                               orientation:UIImageOrientationUpMirrored];
    }
    return img;
}

+ (UIImage *)RTLImageWithContentsOfFile:(NSString *)path {
    UIImage *img = [self RTLImageWithContentsOfFile:path];
    if (img && [RTLTools canDoRTLWork] && [RTLTools evaluateImgToReverse:path]) {
        img = [UIImage imageWithCGImage:img.CGImage
                                  scale:img.scale
                               orientation:UIImageOrientationUpMirrored];
    }
    return img;
}

- (instancetype)initRTLWithContentsOfFile:(NSString *)path {
    self = [self initRTLWithContentsOfFile:path];
    if (self && [RTLTools canDoRTLWork] && [RTLTools evaluateImgToReverse:path]) {
        self = [UIImage imageWithCGImage:self.CGImage
                                  scale:self.scale
                               orientation:UIImageOrientationUpMirrored];
    }
    return self;
}

@end
