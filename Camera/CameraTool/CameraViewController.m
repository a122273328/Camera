//
//  CameraView.m
//  Camera
//
//  Created by wzh on 2017/6/2.
//  Copyright © 2017年 wzh. All rights reserved.
//

#import "CameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ClipViewController.h"
#define KWIDTH [UIScreen mainScreen].bounds.size.width
#define KHEIGHT [UIScreen mainScreen].bounds.size.height
@interface CameraViewController ()<UIGestureRecognizerDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,ClipPhotoDelegate>

/**
 *  AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
 */
@property (nonatomic, strong) AVCaptureSession* session;
/**
 *  输入设备
 */
@property (nonatomic, strong) AVCaptureDeviceInput* videoInput;
/**
 *  照片输出流
 */
@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;
/**
 *  预览图层
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* previewLayer;

/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 * 最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;

@property (nonatomic, strong) AVCaptureConnection *stillImageConnection;

@property (nonatomic, strong) NSData  *jpegData;

@property (nonatomic, assign) CFDictionaryRef attachments;

@property (nonatomic, strong) UIView *toolView;

@property (nonatomic, strong) UIView *editorView;

@property (nonatomic, strong) UIImagePickerController *imgPicker;


@end

@implementation CameraViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self CreatedCamera];
//    [self selectImageFrromCamera];
    
    [self initAVCaptureSession];
    [self setUpGesture];
    [self createdTool];
}

- (void)createdTool
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, KWIDTH, 64)];
    headerView.backgroundColor = [UIColor blackColor];
    headerView.alpha = 0.8;
    [self.view addSubview:headerView];
    
    UILabel *titleLable = [[UILabel alloc] initWithFrame:CGRectMake((KWIDTH - 100)/2.0, 12, 100, 40)];
    titleLable.text = @"拍照";
    [titleLable setTextColor:[UIColor whiteColor]];
    titleLable.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:titleLable];

    UIButton *headerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    headerBtn.frame = CGRectMake(KWIDTH -  80 - 15, 12, 80, 40);
    [headerBtn setTitle:@"取消" forState:UIControlStateNormal];
    [headerBtn addTarget:self action:@selector(cancleCamera) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:headerBtn];
    [self.navigationController.navigationBar.subviews.lastObject setHidden:YES];
    
    self.toolView = [[UIView alloc] initWithFrame:CGRectMake(0, KHEIGHT - 120, KWIDTH, 120)];
    self.toolView.backgroundColor = [UIColor blackColor];
    self.toolView.alpha = 0.8;
    [self.view addSubview:self.toolView];
    
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraBtn.frame = CGRectMake((KWIDTH - 50)/2.0, (120 - 50)/ 2.0, 50, 50);
    [cameraBtn setImage:[UIImage imageNamed:@"takePhoto"] forState:UIControlStateNormal];
    [cameraBtn addTarget:self action:@selector(takePhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.toolView addSubview:cameraBtn];
    
    UIButton *photoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    photoBtn.frame = CGRectMake(((KWIDTH / 2.0) - 30)/2.0, ((120) - 30)/ 2.0, 30, 30);
    [photoBtn addTarget:self action:@selector(openCamera) forControlEvents:UIControlEventTouchUpInside];
    [photoBtn setImage:[UIImage imageNamed:@"cameraPhoto"] forState:UIControlStateNormal];
    [self.toolView addSubview:photoBtn];
    
    UIButton *lampBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    lampBtn.frame = CGRectMake(((KWIDTH / 2.0) - 30)/2.0 + (KWIDTH /2.0), ((120) - 30)/ 2.0, 30, 30);
    [lampBtn setImage:[UIImage imageNamed:@"openFlish"] forState:UIControlStateSelected];
    [lampBtn setImage:[UIImage imageNamed:@"closeFlish"] forState:UIControlStateNormal];
    [lampBtn addTarget:self action:@selector(flashButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolView addSubview:lampBtn];


    
}

- (void)initAVCaptureSession{
    
    self.session = [[AVCaptureSession alloc] init];
    
    NSError *error;
    
    self.effectiveScale = 1.0;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    
    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];

    self.previewLayer.frame = CGRectMake(0, 0,KWIDTH, KHEIGHT);
    self.view.layer.masksToBounds = YES;
    [self.view.layer addSublayer:self.previewLayer];
    
    [self resetFocusAndExposureModes];
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    
    if (self.session) {
        
        [self.session startRunning];
    }
}


- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:YES];
    
    if (self.session) {
        
        [self.session stopRunning];
    }
}
//自动聚焦、曝光
- (BOOL)resetFocusAndExposureModes{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
    BOOL canResetFocus = [device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode];
    BOOL canResetExposure = [device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode];
    CGPoint centerPoint = CGPointMake(0.5f, 0.5f);
    NSError *error;
    if ([device lockForConfiguration:&error]) {
        if (canResetFocus) {
            device.focusMode = focusMode;
            device.focusPointOfInterest = centerPoint;
        }
        if (canResetExposure) {
            device.exposureMode = exposureMode;
            device.exposurePointOfInterest = centerPoint;
        }
        [device unlockForConfiguration];
        return YES;
    }
    else{
        NSLog(@"%@", error);
        return NO;
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self.view];
    [self focusAtPoint:point];
}
//聚焦
- (void)focusAtPoint:(CGPoint)point {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([self cameraSupportsTapToFocus] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeAutoFocus;
            [device unlockForConfiguration];
        }
        else{
            NSLog(@"%@", error);

        }
    }
}

- (BOOL)cameraSupportsTapToFocus {
    return [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] isFocusPointOfInterestSupported];
}

//获取设备方向
-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}
//照相
- (void)takePhotoButtonClick {
    _stillImageConnection = [self.stillImageOutput        connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [_stillImageConnection setVideoOrientation:avcaptureOrientation];
    [_stillImageConnection setVideoScaleAndCropFactor:self.effectiveScale];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:_stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        
        [self jumpImageView:jpegData];
        
    }];

    
    
    
}

//拍照之后调到相片详情页面
-(void)jumpImageView:(NSData*)data{
    ClipViewController *viewController = [[ClipViewController alloc] init];
    UIImage *image = [UIImage imageWithData:data];
    viewController.image = image;
    viewController.picker = _imgPicker;
    viewController.controller = self;
    viewController.delegate = self;
    viewController.isTakePhoto = YES;

    [self presentViewController:viewController animated:NO completion:nil];
    
}


- (void)cancleCamera
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -- TakePhotoDelegate
- (void)takePhoto:(UIImage *)image
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(CameraTakePhoto:)]) {
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.delegate CameraTakePhoto:image];
    }
}



//打开闪光灯
- (void)flashButtonClick:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    if (sender.isSelected == YES) { //打开闪光灯
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSError *error = nil;
        
        if ([captureDevice hasTorch]) {
            BOOL locked = [captureDevice lockForConfiguration:&error];
            if (locked) {
                captureDevice.torchMode = AVCaptureTorchModeOn;
                [captureDevice unlockForConfiguration];
            }
        }
    }else{//关闭闪光灯
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch]) {
            [device lockForConfiguration:nil];
            [device setTorchMode: AVCaptureTorchModeOff];
            [device unlockForConfiguration];
        }
    }
}
//添加手势代理
- (void)setUpGesture
{
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [self.view addGestureRecognizer:pinch];
}

//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.view];
        CGPoint convertedLocation = [self.previewLayer convertPoint:location fromLayer:self.previewLayer.superlayer];
        if ( ! [self.previewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        
        
        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        if (self.effectiveScale < 1.0){
            self.effectiveScale = 1.0;
        }
        
        NSLog(@"%f-------------->%f------------recognizerScale%f",self.effectiveScale,self.beginGestureScale,recognizer.scale);
        
        CGFloat maxScaleAndCropFactor = [[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        
        NSLog(@"%f",maxScaleAndCropFactor);
        if (self.effectiveScale > maxScaleAndCropFactor)
            self.effectiveScale = maxScaleAndCropFactor;
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
        
    }
    
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}

//打开相册
- (void)openCamera
{
    [self openImagePickerControllerWithType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
}


/// 打开ImagePickerController的方法
- (void)openImagePickerControllerWithType:(UIImagePickerControllerSourceType)type
{
    // 设备不可用  直接返回
    if (![UIImagePickerController isSourceTypeAvailable:type]) return;
    
    _imgPicker = [[UIImagePickerController alloc] init];
    _imgPicker.sourceType = type;
    _imgPicker.delegate = self;
    _imgPicker.allowsEditing = NO;
    [self presentViewController:_imgPicker animated:YES completion:nil];
}

#pragma mark - UINavigationControllerDelegate, UIImagePickerControllerDelegate
// 选择照片之后
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [self cropImage:image];
    
    
}

- (void)cropImage: (UIImage *)image {
    ClipViewController *viewController = [[ClipViewController alloc] init];
    viewController.image = image;
    viewController.picker = _imgPicker;
    viewController.controller = self;
    viewController.delegate = self;
    viewController.isTakePhoto = NO;
    [_imgPicker presentViewController:viewController animated:NO completion:nil];
}


#pragma mark -- ClipPhotoDelegate
- (void)clipPhoto:(UIImage *)image
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(CameraTakePhoto:)]) {
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.delegate CameraTakePhoto:image];
    }
}


@end
