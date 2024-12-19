//
//  UICollectionViewFlowLayout+RTL.m
//  Base
//
//  Created by 胡灿 on 2024/11/1.
//

#import "UICollectionViewFlowLayout+RTL.h"
#import "RTLTools.h"

@implementation UICollectionViewFlowLayout (RTL)

- (BOOL)flipsHorizontallyInOppositeLayoutDirection {
    return YES;  // 无需判断语言环境 会自适应
}

@end
