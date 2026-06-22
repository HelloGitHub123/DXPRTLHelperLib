//
//  RTLDirectionMarks.m
//  Base
//
//  Created by 胡灿 on 2024/06/19.
//

#import "RTLDirectionMarks.h"

#pragma mark - Embedding Direction Characters

NSString * _Nonnull const RTLLEFTToRIGHTEmbedding = @"\u202A";
NSString * _Nonnull const RTLRIGHTToLEFTEmbedding = @"\u202B";
NSString * _Nonnull const RTLPopDirectionalFormatting = @"\u202C";

#pragma mark - Override Direction Characters

NSString * _Nonnull const RTLLEFTToRIGHTOverride = @"\u202D";
NSString * _Nonnull const RTLRIGHTToLEFTOverride = @"\u202E";

#pragma mark - Isolation Direction Characters

NSString * _Nonnull const RTLLEFTToRIGHTIsolate = @"\u2066";
NSString * _Nonnull const RTLRIGHTToLEFTIsolate = @"\u2067";
NSString * _Nonnull const RTLFirstStrongIsolate = @"\u2068";
NSString * _Nonnull const RTLPopDirectionalIsolate = @"\u2069";

#pragma mark - Direction Mark Characters

NSString * _Nonnull const RTLLEFTToRIGHTMark = @"\u200E";
NSString * _Nonnull const RTLRIGHTToLEFTMark = @"\u200F";
NSString * _Nonnull const RTLArabicLetterMark = @"\u061C";

#pragma mark - Zero-Width Characters

NSString * _Nonnull const RTLZeroWidthSpace = @"\u200B";
NSString * _Nonnull const RTLZeroWidthNonJoiner = @"\u200C";
NSString * _Nonnull const RTLZeroWidthJoiner = @"\u200D";
