//
//  PlayerControl.m
//  Gesture
//
//  Created by TangYanQiong on 2017/3/29.
//  Copyright © 2017年 TangYanQiong. All rights reserved.
//

#import "PlayerControl.h"
#import "GestureControl.h"
#import "PlayerManager.h"
#import <MediaPlayer/MediaPlayer.h>

@interface PlayerControl () <GestureDelegate>
{
    GestureControl *gestureControl;
    
    GestureObject *leftSlideObj;
    GestureObject *rightSlideObj;
    
    UISlider *volumeViewSlider;
    CGFloat volumeFloat;
    CGFloat brightnessFloat;
    UILabel *showLabel;
}
@property (nonatomic, strong) BasePlayer *player;
@end

@implementation PlayerControl

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.player = [[PlayerManager manager] getPlayerBy:self];
        [self.player setPlayUrl:@"http://192.168.95.114:5000/nn_vod/nn_x64/aWQ9NWFlNDM1MDM5MDkxZjRmZmZjNTMwOTRiMzY1NzllNTImdXJsX2MxPTdhNmY2ZTY3Nzk2OTJmNjI3ODZhMzIzMDMxMzQzMDM0MzEzNDY4NjQyZTc0NzMyMDAwJm5uX2FrPTAxM2U4NDkyZjE3NDFjODZkNjVkZWE4NmEyYjBmMjkzMmMmbnR0bD0yJm5waXBzPTE5Mi4xNjguOTUuMTE0OjUxMDAmbmNtc2lkPTEwMDAwMDEmbmdzPTU4ZGNiYTdmMDAwNDcwYmM1NDhkMWZiOWJjZTI0NGE1Jm5mdD10cyZubl91c2VyX2lkPSZuZHQ9cGhvbmUmbmRpPTNmYWQxZjQzYWQwMzhiOTM4ZjJlNjQxYjZhZDFiMGYwJm5kdj0yLjMuMi4wLjIuU0MtTGluZ2NvZFRWLUlQSE9ORS4wLjBfUmVsZWFzZSZuc3Q9aXB0diZubl90cmFjZV9pZD01OGRjYmEyNzNmZWU2MTA3ZDRmNjU0MmY4NjI0MTVjNA,,/5ae435039091f4fffc53094b36579e52.m3u8"];
        [self.player play];
        
        //获取MPVolumeSlider实例,MPVolumeSlider的父类是slider,可以通过它来控制系统音量
        MPVolumeView *volumeView = [[MPVolumeView alloc] init];
        for (UIView *view in [volumeView subviews]){
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
                volumeViewSlider = (UISlider*)view;
                break;
            }
        }
        volumeFloat = volumeViewSlider.value;
        
        showLabel = [[UILabel alloc] initWithFrame:self.bounds];
        showLabel.textColor = [UIColor redColor];
        showLabel.textAlignment = NSTextAlignmentCenter;
        showLabel.font = [UIFont boldSystemFontOfSize:20];
        [self addSubview:showLabel];
        
        GestureObject *slideAllObj = [[GestureObject alloc] init];
        slideAllObj.type = SDK_GESTURE_TYPE_SP_SLIDE;
        slideAllObj.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        slideAllObj.moveInterval = 20.f;
        //[GestureControl createControlSignleBy:slideAllObj withTarget:self];
        
        GestureObject *clickObj = [[GestureObject alloc] init];
        clickObj.type = SDK_GESTURE_TYPE_CLICK;
        clickObj.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        //[GestureControl createControlSignleBy:clickObj withTarget:self];
        
        leftSlideObj = [[GestureObject alloc] init];
        leftSlideObj.type = SDK_GESTURE_TYPE_SZ_SLIDE;
        leftSlideObj.frame = CGRectMake(0, 0, frame.size.width/2, frame.size.height);
        leftSlideObj.moveInterval = 30.f;
        
        rightSlideObj = [[GestureObject alloc] init];
        rightSlideObj.type = SDK_GESTURE_TYPE_SZ_SLIDE;
        rightSlideObj.frame = CGRectMake(frame.size.width/2, 0, frame.size.width/2, frame.size.height);
        rightSlideObj.moveInterval = 30.f;
        
        gestureControl = [GestureControl createControlMultipleBy:frame withObjects:@[slideAllObj,clickObj, leftSlideObj, rightSlideObj] target:self];
        
        brightnessFloat = [UIScreen mainScreen].brightness;
    }
    return self;
}

- (void)SP_slideEventWith:(UISwipeGestureRecognizerDirection)gestureDirection slideType:(SDK_SLIDE_TYPE)slideType andObject:(GestureObject *)gestureObj
{
    if (gestureDirection == UISwipeGestureRecognizerDirectionLeft) {
        showLabel.text = @"左滑动";
        [self.player seekToTime:self.player.currentTime-30.f];
        
    }else {
        showLabel.text = @"右滑动";
        [self.player seekToTime:self.player.currentTime+30.f];
    }
    
    //Just Log
    if (slideType == SDK_SLIDE_TYPE_END){
        if (gestureDirection == UISwipeGestureRecognizerDirectionLeft) {
            NSLog(@"左滑动end");
        }else{
            NSLog(@"右滑动end");
        }
    }else {
        NSLog(@"sp_text:%@", showLabel.text);
    }
    //
}

- (void)SZ_slideEventWith:(UISwipeGestureRecognizerDirection)gestureDirection slideType:(SDK_SLIDE_TYPE)slideType andObject:(GestureObject *)gestureObj
{
    if ([gestureObj isEqual:leftSlideObj]) {
        if (gestureDirection == UISwipeGestureRecognizerDirectionUp) {
            showLabel.text = @"左边区域上滑动";
            volumeFloat = volumeFloat+0.2;
            volumeViewSlider.value = volumeFloat;
        }else {
            showLabel.text = @"左边区域下滑动";
            volumeFloat = volumeFloat-0.2;
            volumeViewSlider.value = volumeFloat;
        }
   }else if ([gestureObj isEqual:rightSlideObj]){
        if (gestureDirection == UISwipeGestureRecognizerDirectionUp) {
            showLabel.text = @"右边区域上滑动";
            brightnessFloat = brightnessFloat+0.3;
            [[UIScreen mainScreen] setBrightness:brightnessFloat];
        }else {
            showLabel.text = @"右边区域下滑动";
            brightnessFloat = brightnessFloat-0.3;
            [[UIScreen mainScreen] setBrightness:brightnessFloat];
        }
       
   }
    
    //Just Log
    if (slideType == SDK_SLIDE_TYPE_END) {
        if ([gestureObj isEqual:leftSlideObj]) {
            if (gestureDirection == UISwipeGestureRecognizerDirectionUp) {
                NSLog(@"左边区域上滑动end");
            }else{
                NSLog(@"左边区域下滑动end");
            }
        }else if ([gestureObj isEqual:rightSlideObj]){
            if (gestureDirection == UISwipeGestureRecognizerDirectionUp) {
                NSLog(@"右边区域上滑动end");
            }else {
                NSLog(@"右边区域下滑动end");
            }
            
        }
    }else{
        NSLog(@"sz_text:%@", showLabel.text);
    }
    //
}

- (void)clickEvent:(NSUInteger)clickTimes
{
    showLabel.text = [NSString stringWithFormat:@"点击次数：%ld", clickTimes];
}

- (void)layoutSubviews
{
    gestureControl.frame = self.frame;
    showLabel.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    [self.player setPlayerViewFrame:self.frame];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
