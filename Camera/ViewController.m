//
//  ViewController.m
//  Camera
//
//  Created by wzh on 2017/6/2.
//  Copyright © 2017年 wzh. All rights reserved.
//

#import "ViewController.h"
#import "CameraViewController.h"

@interface ViewController ()<CameraDelegate>

@property(nonatomic, strong) CameraViewController *cameraViewvController;

@property (nonatomic, strong)  UIImageView *imgeView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(100, 100, 100, 100);
    btn.backgroundColor = [UIColor redColor];
    [btn addTarget:self action:@selector(cameraAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
}

- (void)cameraAction
{
    self.cameraViewvController = [[CameraViewController alloc] init];
    self.cameraViewvController.delegate = self;
    //self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    [self presentViewController:self.cameraViewvController animated:YES completion:nil];
    
    
}
//选取照片的回调
- (void)CameraTakePhoto:(UIImage *)image
{
    NSLog(@"-----%@",image);
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
