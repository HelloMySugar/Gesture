//
//  PlayerManager.m
//  PlayerManager
//
//  Created by TangYanQiong on 15/8/13.
//  Copyright (c) 2015年 Starcor. All rights reserved.
//

#import "PlayerManager.h"
#import "ReAVPlayer.h"

@implementation PlayerManager

+ (PlayerManager *)manager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharePlayerManager = nil;
    dispatch_once(&pred, ^{
        _sharePlayerManager = [[self alloc] init];
    });
    
    return _sharePlayerManager;
}

- (BasePlayer *)getPlayerBy:(UIView *)playerView
{
#if SHOW_DRM_PLAYER
    return nil;
#else
    return [[ReAVPlayer alloc] initWithPlayerView:playerView];
#endif
}

- (BasePlayer *)getPlayerBy:(UIView *)playerView andPlayerType:(PlayerManagerType)playerType
{
    switch (playerType) {
        case PlayerManagerTypeAVPlayer:
            return [[ReAVPlayer alloc] initWithPlayerView:playerView];
            break;
        default:
            return nil;
            break;
    }
}

@end
