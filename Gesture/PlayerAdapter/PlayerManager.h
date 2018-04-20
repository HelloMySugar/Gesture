//
//  PlayerManager.h
//  PlayerManager
//
//  Created by TangYanQiong on 15/8/13.
//  Copyright (c) 2015年 Starcor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BasePlayer.h"

#define SHOW_DRM_PLAYER       0

/**
 播放器类型，目前有系统播放器及DRM播放器
 */
typedef enum _PlayerManagerType
{
    PlayerManagerTypeNone = 0,
    PlayerManagerTypeAVPlayer = 1,
    PlayerManagerTypeVisualOnPlayer = 2
} PlayerManagerType;

@interface PlayerManager : NSObject

/**
 *  播放器管理类
 *
 *  @return 获得播放器管理类单利
 */
+ (PlayerManager *)manager;

/**
 *  设置播放器的显示层View
 *
 *  @param playerView 传入要加载播放器的View
 *
 *  @return 返回播放器，基于BasePlayer对象，注意：该BasePlayer对象需写成全局对象，不然的话，由于ARC自动管理内存，会过早释放，导致收不到视频播放状态回调
 */
- (BasePlayer *)getPlayerBy:(UIView *)playerView;

/**
 *  同上
 *
 *  @param playerView 同上
 *  @param playerType 可以传不同Type获取到不同播放器
 *
 *  @return 同上
 */
- (BasePlayer *)getPlayerBy:(UIView *)playerView andPlayerType:(PlayerManagerType)playerType;

@end
