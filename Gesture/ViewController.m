//
//  ViewController.m
//  Gesture
//
//  Created by TangYanQiong on 2017/3/27.
//  Copyright © 2017年 TangYanQiong. All rights reserved.
//

#import "ViewController.h"
#import "PlayerControl.h"

@interface ViewController ()
{
    PlayerControl *playerControl;
}
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    playerControl = [[PlayerControl alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 200)];
    [self.view addSubview:playerControl];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (size.width >size.height) {
        playerControl.frame = CGRectMake(0, 0, size.width, size.height);
    }else{
        playerControl.frame = CGRectMake(0, 0, size.width, 200);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
