//
//  BasePlayer.h
//  PlayerManager
//
//  Created by TangYanQiong on 15/8/13.
//  Copyright (c) 2015年 Starcor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 播放器的播放状态
 */
typedef enum {
    TD_PLAYER_STATE_READY,                  //视频准备播放了
    TD_PLAYER_STATE_PLAYING,                //视频播放了
    TD_PLAYER_STATE_PAUSE,                  //视频播放暂停
    TD_PLAYER_STATE_STOP,                   //视频播放停止
    TD_PLAYER_STATE_START_BUFFER,           //视频播放开始缓冲
    TD_PLAYER_STATE_END_BUFFER,             //视频播放缓冲结束
    TD_PLAYER_STATE_FINISH,                 //视频播放完成
    TD_PLAYER_STATE_FAILED,                 //视频播放失败
    TD_PLAYER_STATE_ERROR,                  //视频播放错误
    TD_PLAYER_STATE_RETRY,                  //视频播放重试
} TD_PLAYER_STATE;

/**
 *  播放器的代理
 */
@protocol PlayerDelegate <NSObject>
@required
- (void)showPlayerState:(TD_PLAYER_STATE)playerState;//可以获取到当前视频状态
@optional
- (void)videoCurrentPlayTime:(NSInteger)playTime;//可以获取到视频当前的播放时间
- (void)videoCurrentProgress:(CGFloat)progress;//可以获取到缓冲进度
@end

@interface BasePlayer : NSObject
@property (nonatomic, assign) id <PlayerDelegate> delegate;
@property (nonatomic, readonly) CGFloat duration;//视频总时长，须在子类里实现其get方法
@property (nonatomic, readonly) CGFloat currentTime;//当前播放时间，须在子类里实现get方法
@property (nonatomic, readonly) BOOL isLive;//视频是否是直播，须在子类里实现get方法
@property (nonatomic) BOOL isPlaying;//视频是否正在播放状态
@property (nonatomic) NSInteger retryTimes;//播放出错后的重试次数，默认为3次，外部可传入

/**
 *  初始化播放器，并同时设置加载播放器的View
 *
 *  @param playerView 传入要加载播放器的View
 *
 *  @return 返回播放器对象
 */
- (id)initWithPlayerView:(UIView *)playerView;

/**
 *  设置播放器View的Frame
 *
 *  @param frame 传入要改变的Frame
 */
- (void)setPlayerViewFrame:(CGRect)frame;

/**
 *  设置播放地址
 *
 *  @param playUrl 传入视频url
 */
- (void)setPlayUrl:(NSString *)playUrl;

/**
 *  可以调用下面三个方法，对播放器进行播放、暂停、停止操作
 */
- (void)play;
- (void)pause;
- (void)stop;

/**
 *  对视频重新播放，将从0开始播放
 */
- (void)replay;

/**
 *  播放器取消播放
 */
- (void)cancel;

/**
 *  设置播放器想要播放时间点
 *
 *  @param seekTime 传入要设置的播放时间点
 */
- (void)seekToTime:(CGFloat)seekTime;

/**
 *  获取当前视频播放网速
 *
 *  @return 返回网速
 */
- (NSString *)getNetworkSpeed;

/**
 *  获取视频截图
 *
 *  @return 返回视频桢图截图
 */
- (UIImage *)getScreenshot;

/**
 *  关闭播放器，注：在生成了播放器，须调用该方法关闭播放器，以免出现系统Crash
 */
- (void)close;

@end
