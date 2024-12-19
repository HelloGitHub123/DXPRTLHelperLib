//
//  RTLConfigurationManager.m
//  Base
//
//  Created by 胡灿 on 2024/11/26.
//

#import "RTLConfigurationManager.h"

@implementation RTLConfigurationManager

+ (instancetype)sharedInstance {
    static RTLConfigurationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[RTLConfigurationManager alloc]init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _currentLanSemanticStyle = UISemanticContentAttributeForceLeftToRight;
        _enableRTLCategoryWork = YES;
        _locale = [[NSLocale preferredLanguages] objectAtIndex:0];
        _needReverseImgs = [[NSMutableSet alloc]init];
        _needReverseImgWithRegulars = [[NSMutableSet alloc]init];
        _keepOriginImgs = [[NSMutableSet alloc]init];
        _atomViewClasses = [[NSSet alloc] initWithArray:@[
            // UIControl
            [UIButton class],
            [UISlider class],
            [UISegmentedControl class],
            [UISwitch class],
            [UIProgressView class],
            [UIPageControl class],
            [UIDatePicker class],
            // UIView
            [UILabel class],
            [UITextField class],
            [UITextView class],
            [UISearchBar class],
            [UIAlertView class],
//            [UIScrollView class],
        ]];
    }
    return self;
}

#pragma mark -- setter

- (void)setCurrentLanSemanticStyle:(UISemanticContentAttribute)currentLanSemanticStyle {
    if (_currentLanSemanticStyle == currentLanSemanticStyle) {

    } else {
        // 要设置的currentLanSemanticStyle 与当前的currentLanSemanticStyle不一致
        _currentLanSemanticStyle = currentLanSemanticStyle;
        if(currentLanSemanticStyle == UISemanticContentAttributeForceRightToLeft) {
            [UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    //        [UIScrollView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    //        [UIImageView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
//            [UITextField appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
//            [UIButton appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
            [UILabel appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
            [UISwitch appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
            [UIPageControl appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
            [UICollectionView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        } else {
            [UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    //        [UIScrollView appearance].semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    //        [UIImageView appearance].semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
//            [UITextField appearance].semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
//            [UIButton appearance].semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
            [UILabel appearance].semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
            [UISwitch appearance].semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
            [UIPageControl appearance].semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
            [UICollectionView appearance].semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
    }
}

@end
