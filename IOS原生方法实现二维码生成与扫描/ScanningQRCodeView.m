//
//  ScanningQRCodeView.m
//  IOS原生方法实现二维码生成与扫描
//
//  Created by changcai on 17/5/4.
//  Copyright © 2017年 changcai. All rights reserved.
//

#import "ScanningQRCodeView.h"

#define kScreen_Width  CGRectGetWidth([UIScreen mainScreen].bounds)
#define kScreen_Height  CGRectGetHeight([UIScreen mainScreen].bounds)
/** 扫描内容的Y值 */
#define scanContent_Y self.frame.size.height * 0.24
/** 扫描内容的Y值 */
#define scanContent_X self.frame.size.width * 0.15

@interface ScanningQRCodeView()

@property (nonatomic, strong) CALayer *contentLayer;
@property (nonatomic, strong) UIImageView *scanningline;
@property (nonatomic, strong)  dispatch_source_t timer;

@end

@implementation ScanningQRCodeView

#pragma mark -- Lazy loading --
- (CALayer*)contentLayer {
    if (!_contentLayer) {
        _contentLayer = [[CALayer alloc] init];
    }
    return _contentLayer;
}

- (UIImageView *)scanningline {
    
    if (!_scanningline) {
        _scanningline = [[UIImageView alloc] init];
        _scanningline.backgroundColor = [UIColor greenColor];
        _scanningline.frame = CGRectMake(scanContent_X , scanContent_Y, self.frame.size.width - scanContent_X*2,2);
    }
    return _scanningline;
}

- (instancetype)initWithFrame:(CGRect)frame layer:(CALayer *)layer {
    if (self = [super initWithFrame:frame]) {
        self.contentLayer = layer;
      // 布局扫描界面
      [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews
{
    
    
    CGFloat scanContent_layerX = scanContent_X;
    CGFloat scanContent_layerY = scanContent_Y;
    CGFloat scanContent_layerW = self.frame.size.width - 2 * scanContent_X;
    CGFloat scanContent_layerH = scanContent_layerW;
    UIBezierPath* borderPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, scanContent_layerW, scanContent_layerH)];
    CAShapeLayer* borderLayer = [CAShapeLayer layer];
    borderLayer.path = borderPath.CGPath;
    borderLayer.fillColor = [UIColor clearColor].CGColor;
    borderLayer.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.6].CGColor;
    borderLayer.lineWidth = 0.7;
    borderLayer.frame = CGRectMake(scanContent_layerX, scanContent_layerY, scanContent_layerW, scanContent_layerH);
    [self.contentLayer addSublayer:borderLayer];
    
    /*
    //扫描内容的创建
    CALayer *scanContent_layer = [[CALayer alloc] init];
    CGFloat scanContent_layerX = scanContent_X;
    CGFloat scanContent_layerY = scanContent_Y;
    CGFloat scanContent_layerW = self.frame.size.width - 2 * scanContent_X;
    CGFloat scanContent_layerH = scanContent_layerW;
    scanContent_layer.frame = CGRectMake(scanContent_layerX, scanContent_layerY, scanContent_layerW, scanContent_layerH);
    scanContent_layer.borderColor = [[UIColor redColor] colorWithAlphaComponent:0.6].CGColor;
    scanContent_layer.borderWidth = 0.7;
    scanContent_layer.backgroundColor = [UIColor clearColor].CGColor;
    [self.contentLayer addSublayer:scanContent_layer];
     */
}

#pragma mark - - - 添加定时器 ----
- (void)addTimer
{
    // 扫描动画添加
    [self.contentLayer addSublayer:self.scanningline.layer];
    // 全局队列
    dispatch_queue_t  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_timer, ^{
       dispatch_async(dispatch_get_main_queue(), ^{
          [self timeAction];//主线程开始动画
       });
    });
    dispatch_resume(_timer);
}
#pragma mark - - - 移除定时器 ---
- (void)removeTimer
{
    if(_timer){
       dispatch_source_cancel(_timer);
       self.timer = nil;
    }
    [self.scanningline.layer removeFromSuperlayer];
    self.scanningline = nil;
}
#pragma mark - - - 执行定时器方法
- (void)timeAction
{
    __block CGRect frame = _scanningline.frame;
    static BOOL flag = YES;
    if (flag) {
        frame.origin.y = scanContent_Y;
        flag = NO;
        [UIView animateWithDuration:0.05 animations:^{
            frame.origin.y += 5;//5为间距，值越大，走的越快
            _scanningline.frame = frame;
        } completion:nil];
    } else {
        if (_scanningline.frame.origin.y >= scanContent_Y) {
            //最大的Y值
            CGFloat scanContent_MaxY = scanContent_Y + self.frame.size.width - 2 * scanContent_X;
            if (_scanningline.frame.origin.y >= scanContent_MaxY - 5) {
                //从头开始
                frame.origin.y = scanContent_Y;
                _scanningline.frame = frame;
                flag = YES;
            } else {
                [UIView animateWithDuration:0.05 animations:^{
                    frame.origin.y += 5;
                    _scanningline.frame = frame;
                } completion:nil];
            }
        } else {
            flag = !flag;
        }
    }
}

@end
