//
//  UIImage+CreatedQR.h
//  IOS原生方法实现二维码生成与扫描
//
//  Created by changcai on 17/5/4.
//  Copyright © 2017年 changcai. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,kQRCodeCorrectionLevel)
{
    kQRCodeCorrectionLevelLow = 0,
    kQRCodeCorrectionLevelNormal,
    kQRCodeCorrectionLevelSuperior,
    kQRCodeCorrectionLevelHight
};

@interface UIImage (CreatedQR)

+ (UIImage *)qrImageForString:(NSString *)string  correctionLevel:(kQRCodeCorrectionLevel)corLevel imageSize:(CGFloat)Imagesize logoImageSize:(CGFloat)waterImagesize;
+ (UIImage *)imageSizeWithScreenImage:(UIImage *)image;
@end
