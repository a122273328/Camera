//
//  CameraView.h
//  Camera
//
//  Created by wzh on 2017/6/2.
//  Copyright © 2017年 wzh. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CameraDelegate <NSObject>

- (void)CameraTakePhoto:(UIImage *)image;

@end

@interface CameraViewController : UIViewController

@property (nonatomic, weak)id<CameraDelegate> delegate;



@end
