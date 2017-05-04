//
//  ScanningQRCodeView.h
//  IOS原生方法实现二维码生成与扫描
//
//  Created by changcai on 17/5/4.
//  Copyright © 2017年 changcai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScanningQRCodeView : UIView
- (instancetype)initWithFrame:(CGRect)frame layer:(CALayer *)layer;
- (void)addTimer;
- (void)removeTimer;
@end
