//
//  ViewController.m
//  IOS原生方法实现二维码生成与扫描
//
//  Created by changcai on 17/5/4.
//  Copyright © 2017年 changcai. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "UIImage+CreatedQR.h"
#import "ScanningQRCodeView.h"
#import "ScanSuccessViewController.h"
@interface ViewController () <AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
/** 会话对象 */
@property (nonatomic, strong) AVCaptureSession *session;
/** 图层类 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
/**   */
@property (nonatomic, strong) UIImageView *imageView;
/**   */
@property (nonatomic, strong) ScanningQRCodeView *scanQRCodeView;

@end

@implementation ViewController

#pragma mark -- Lazy loading --
- (ScanningQRCodeView*)scanQRCodeView {
    if (!_scanQRCodeView) {
        _scanQRCodeView = [[ScanningQRCodeView alloc] initWithFrame:self.view.bounds layer:self.view.layer];
    }
    return _scanQRCodeView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:(UIBarButtonItemStyleDone) target:self action:@selector(rightBarButtonItenAction)];
    [self.view addSubview:self.scanQRCodeView];
    [self setupSGQRCodeScanning];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.scanQRCodeView addTimer];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.scanQRCodeView removeTimer];
}

- (void)dealloc {
    [self removeScanningView];
}
- (void)rightBarButtonItenAction {
    [self readImageFromAlbum];
    dispatch_queue_t queue = dispatch_queue_create("ScanningQR", DISPATCH_QUEUE_CONCURRENT);
    //栅栏函数
    dispatch_barrier_async(queue, ^{
        //[self removeScanningView];
    });
}
- (void)removeScanningView {
    
    [self.scanQRCodeView removeTimer];
    [self.scanQRCodeView removeFromSuperview];
    self.scanQRCodeView = nil;
}
//+++++++++++++++++++++++++++++++++++++++++相册中扫描二维码+++++++++++++++++++++++++++++++++++++++++
- (void)readImageFromAlbum {
    
    // 1、 获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        // 判断授权状态
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusNotDetermined) { // 用户还没有做出选择
            // 弹框请求用户授权
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) { // 用户第一次同意了访问相册权限
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary; //（选择类型）表示仅仅从相册中选取照片
                        imagePicker.delegate = self;
                        [self presentViewController:imagePicker animated:YES completion:nil];
                    });
                } else { //用户第一次拒绝了访问相机权限
                    
                }
            }];
            
        } else if (status == PHAuthorizationStatusAuthorized) { // 用户允许当前应用访问相册
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary; //（选择类型）表示仅仅从相册中选取照片
            imagePicker.delegate = self;
            [self presentViewController:imagePicker animated:YES completion:nil];
            
        } else if (status == PHAuthorizationStatusDenied) { // 用户拒绝当前应用访问相册
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"⚠️ 警告" message:@"请去-> [设置 - 隐私 - 照片 - SGQRCodeExample] 打开访问开关" preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
        } else if (status == PHAuthorizationStatusRestricted) {
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"由于系统原因, 无法访问相册" preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
        }
    }
}
#pragma mark - - - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    //[self.view addSubview:self.scanQRCodeView];
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"---------当前线程：%@------",[NSThread currentThread]);
        //[self scanQRCodeFromPhotosInTheAlbum:[info objectForKey:@"UIImagePickerControllerOriginalImage"]];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    //[self.view addSubview:self.scanQRCodeView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - - - 从相册中识别二维码, 并进行界面跳转
- (void)scanQRCodeFromPhotosInTheAlbum:(UIImage *)image {
    // 对选取照片的处理，如果选取的图片尺寸过大，则压缩选取图片，否则不作处理
    image = [UIImage imageSizeWithScreenImage:image];
    // CIDetector(CIDetector可用于人脸识别)进行图片解析，从而使我们可以便捷的从相册中获取到二维码
    // 声明一个CIDetector，并设定识别类型 CIDetectorTypeQRCode
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    // 取得识别结果
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    if(features.count > 0){
        for (int index = 0; index < [features count]; index ++) {
            CIQRCodeFeature *feature = [features objectAtIndex:index];
            NSString *scannedResult = feature.messageString;
            //SGQRCodeLog(@"scannedResult - - %@", scannedResult);
            // 在此发通知，告诉子类二维码数据
            [self QRCodeInformationFromeScanning:scannedResult];
        }
    }
}


//+++++++++++++++++++++++++++++++++++++++++摄像头扫描二维码+++++++++++++++++++++++++++++++++++++++++

- (void)setupSGQRCodeScanning {
    // 1、获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 2、创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    // 3、创建输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    // 4、设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    // 设置扫描范围(每一个取值0～1，以屏幕右上角为坐标原点)
    // 注：微信二维码的扫描范围是整个屏幕，这里并没有做处理（可不用设置）
    output.rectOfInterest = CGRectMake(0.05, 0.2, 0.7, 0.6);
    // 5、初始化链接对象（会话对象）
    self.session = [[AVCaptureSession alloc] init];
    // 高质量采集率
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    // 5.1 添加会话输入
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    // 5.2 添加会话输出
    if ([self.session canAddOutput:output]) {
        [self.session addOutput:output];
    }
    // 6、设置输出数据类型，需要将元数据输出添加到会话后，才能指定元数据类型，否则会报错
    // 设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code,  AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    // 7、实例化预览图层, 传递_session是为了告诉图层将来显示什么内容
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = self.view.layer.bounds;
    // 8、将图层插入当前视图
    [self.view.layer insertSublayer:_previewLayer atIndex:0];
    // 9、启动会话
    [_session startRunning];
}

#pragma mark - - - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    // 0、扫描成功之后的提示音
    [self SG_playSoundEffect:@"sound.caf"];
    // 1、如果扫描完成，停止会话
    [self.session stopRunning];
    // 2、删除预览图层
    [self.previewLayer removeFromSuperlayer];
    // 3、设置界面显示扫描结果
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        // 在此发通知，告诉子类二维码数据
        NSLog(@"-----%@------",obj.stringValue);
        [self QRCodeInformationFromeScanning:obj.stringValue];
    }
}

/** 播放音效文件 */
- (void)SG_playSoundEffect:(NSString *)name {
    // 获取音效
    NSString *audioFile = [[NSBundle mainBundle] pathForResource:name ofType:nil];
    NSURL *fileUrl = [NSURL fileURLWithPath:audioFile];
    
    // 1、获得系统声音ID
    SystemSoundID soundID = 0;
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(fileUrl), &soundID);
    
    AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, soundCompleteCallback, NULL);
    
    // 2、播放音频
    AudioServicesPlaySystemSound(soundID); // 播放音效
}
/** 播放完成回调函数 */
void soundCompleteCallback(SystemSoundID soundID, void *clientData){
    //SGQRCodeLog(@"播放完成...");
}

- (void)QRCodeInformationFromeScanning:(NSString *)scanningInfo {
      ScanSuccessViewController *jumpVC = [[ScanSuccessViewController alloc] init];
       if ([scanningInfo hasPrefix:@"http"]) {// 扫描结果为二维码
           jumpVC.jump_URL = scanningInfo;
    } else { // 扫描结果为条形码
           jumpVC.jump_bar_code = scanningInfo;
    }
    if( jumpVC.jump_URL.length > 0 || jumpVC.jump_bar_code.length > 0){
        [self.navigationController pushViewController:jumpVC animated:YES];
    }
}



//创建二维码
- (void)createdQRCode
{
    NSString *urlStr = @"http://www.ychpay.com/down.html";//测试二维码地址
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(35, 80, 80, 80)];
    self.imageView.image = [UIImage qrImageForString:urlStr  correctionLevel:kQRCodeCorrectionLevelHight  imageSize:80 logoImageSize:40];
    [self.view addSubview:self.imageView];
}



@end
