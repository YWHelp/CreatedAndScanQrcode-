//
//  UIImage+CreatedQR.m
//  IOS原生方法实现二维码生成与扫描
//
//  Created by changcai on 17/5/4.
//  Copyright © 2017年 changcai. All rights reserved.
//

#import "UIImage+CreatedQR.h"

@implementation UIImage (CreatedQR)
//思路：CIFilter ---> CIImage ---> CGImageRef ---> UIImage
+ (UIImage *)qrImageForString:(NSString *)string  correctionLevel:(kQRCodeCorrectionLevel)corLevel imageSize:(CGFloat)Imagesize logoImageSize:(CGFloat)waterImagesize{
    // 1. 实例化二维码滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 2. 恢复滤镜的默认属性
    [filter setDefaults];
    // 3. 将字符串转换成NSData
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    //4.通过kvo方式给一个字符串，生成二维码
    [filter setValue:data forKey:@"inputMessage"];
    //设置二维码的纠错水平，越高纠错水平越高，可以污损的范围越大
    NSString *corLevelStr = nil;
    switch (corLevel) {
        case kQRCodeCorrectionLevelLow:
            corLevelStr = @"L";
            break;
        case kQRCodeCorrectionLevelNormal:
            corLevelStr = @"M";
            break;
        case kQRCodeCorrectionLevelSuperior:
            corLevelStr = @"Q";
            break;
        case kQRCodeCorrectionLevelHight:
            corLevelStr = @"H";
            break;
    }
    [filter setValue:corLevelStr forKey:@"inputCorrectionLevel"];
     //5.获得滤镜输出的图像
    CIImage *outPutImage = [filter outputImage];//拿到二维码图片
    return [[self alloc] createNonInterpolatedUIImageFormCIImage:outPutImage withSize:Imagesize waterImageSize:waterImagesize];
}

//处理模糊的方法
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size waterImageSize:(CGFloat)waterImagesize{
    
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    //创建一个DeviceGray颜色空间
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    //CGBitmapContextCreate(void * _Nullable data, size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow, CGColorSpaceRef  _Nullable space, uint32_t bitmapInfo)
    //width：图片宽度像素
    //height：图片高度像素
    //bitsPerComponent：每个颜色的比特值，例如在rgba-32模式下为8
    //bitmapInfo：指定的位图应该包含一个alpha通道。
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    //创建CoreGraphics image
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    //2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    
    //3.获取原图
    UIImage *outputImage = [UIImage imageWithCGImage:scaledImage];
    
    //4.修改二维码的颜色
    UIImage *colorOutImage = [self  imageBlackToTransparent:outputImage withRed:125 andGreen:202 andBlue:88];
    //给二维码加logo图
    //开启图像上下文
    UIGraphicsBeginImageContextWithOptions(colorOutImage.size, NO, [[UIScreen mainScreen] scale]);
    [colorOutImage drawInRect:CGRectMake(0,0 , size, size)];
    //logo图
    UIImage *waterimage = [UIImage imageNamed:@"ceshi"];
    //把logo图画到生成的二维码图片上，注意尺寸不要太大（最大不超过二维码图片的%30），太大会造成扫不出来
    [waterimage drawInRect:CGRectMake((size-waterImagesize)/2.0, (size-waterImagesize)/2.0, waterImagesize, waterImagesize)];
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    //关闭图像上下文
    UIGraphicsEndImageContext();
    return newPic;
}

//修改二维码的颜色，图片要传没有加过标志的(网上查找的)
- (UIImage*)imageBlackToTransparent:(UIImage*)image withRed:(CGFloat)red andGreen:(CGFloat)green andBlue:(CGFloat)blue{
    
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage); // 遍历像素
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++){
        if ((*pCurPtr & 0xFFFFFF00) < 0x99999900) //将白色变成透明
        {
            // 改成下面的代码，会将图片转成想要的颜色
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[3] = red; //0~255
            ptr[2] = green;
            ptr[1] = blue;
        } else {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
        }
    }
    // 输出图片
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, nil);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace, kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef]; // 清理空间
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return resultUIImage;
}
/// 返回一张不超过屏幕尺寸的 image
+ (UIImage *)imageSizeWithScreenImage:(UIImage *)image {
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat screenHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
    
    // 如果读取的二维码照片宽和高小于屏幕尺寸，直接返回原图片
    if (imageWidth <= screenWidth && imageHeight <= screenHeight) {
        return image;
    }
    //SGQRCodeLog(@"压缩前图片尺寸 － width：%.2f, height: %.2f", imageWidth, imageHeight);
    CGFloat max = MAX(imageWidth, imageHeight);
    // 如果是6plus等设备，比例应该是 3.0
    CGFloat scale = max / (screenHeight * 2.0f);
    //SGQRCodeLog(@"压缩后图片尺寸 － width：%.2f, height: %.2f", imageWidth / scale, imageHeight / scale);
    
    return [UIImage imageWithImage:image scaledToSize:CGSizeMake(imageWidth / scale, imageHeight / scale)];
}
/// 返回一张处理后的图片
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


@end
