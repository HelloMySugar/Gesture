//
//  ReAVPlayer.m
//
//  Created by TangYanQiong on 15/8/13.
//  Copyright (c) 2015年 Starcor. All rights reserved.
//

#import "ReAVPlayer.h"
#import "BasePlayer_Methods.h"

#define kVideoRequestTimeoutSecond   30

#define PlayerItemStatus             @"status"
#define PlayerItemLoadedTimeRanges   @"loadedTimeRanges"

@interface ReAVPlayer ()
{
    UIView *playerView;//播放器加载View
    AVPlayerLayer *playerLayer;//播放器Layer
    AVPlayerItemVideoOutput *playerItemVideoOutput;//截图使用
    
    //播放器内部
    AVPlayer *avPlayer;
    AVPlayerItem *avPlayerItem;
    id playbackTimeObserver;
    
    //缓冲
    NSInteger cacheArrayCount;
    CGFloat beforeCacheSize;
    NSString *nowNetworkSpeed;//当前网速
    
    NSInteger nowPlayedTime;//当前播放时间，为NSIntger类型是因为有时候不到一秒也会回调播放函数
    
    BOOL isClose;//Player已被关闭
    
    NSTimer *timeoutTimer;//这种是针对于视频一直播放不出来，但是且收不到失败回调的处理
    
    NSInteger retryCountdownTimes;//重试机制倒计次数
}

@property (nonatomic) BOOL isBufferLoading;//当前播放器是否是在缓冲加载中

/**
 *  更新播放状态给外部调用者
 *
 *  @param playerState 播放器状态
 */
- (void)updateVideoStateToTheCaller:(TD_PLAYER_STATE)playerState;

@end

@implementation ReAVPlayer

#pragma mark - SET Methods -

- (void)setRetryTimes:(NSInteger)retryTimes
{
    [super setRetryTimes:retryTimes];
    retryCountdownTimes = retryTimes;
}

#pragma mark - GET Methods -

- (CGFloat)duration
{
    if (isnan(CMTimeGetSeconds(avPlayer.currentItem.duration)) || CMTimeGetSeconds(avPlayer.currentItem.duration) <= 0)
        return 0.f;
    else
        return CMTimeGetSeconds(avPlayer.currentItem.duration);
}

- (CGFloat)currentTime
{
    return CMTimeGetSeconds(avPlayer.currentItem.currentTime);
}

- (BOOL)isLive
{
    if (isnan(CMTimeGetSeconds(avPlayer.currentItem.duration)) || CMTimeGetSeconds(avPlayer.currentItem.duration) <= 0)
        return YES;
    else
        return NO;
}

#pragma mark -

- (id)initWithPlayerView:(UIView *)_playerView
{
    if (self = [super init])
    {
        playerView = _playerView;
    }
    return self;
}

- (void)addOrRemoveNotification:(BOOL)isAdd
{
    if (isAdd)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayStalled:)
                                                     name:AVPlayerItemPlaybackStalledNotification
                                                   object:avPlayerItem];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayDidEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:avPlayerItem];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayError:)
                                                     name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                   object:avPlayerItem];
        
        [avPlayerItem addObserver:self
                       forKeyPath:PlayerItemStatus
                          options:NSKeyValueObservingOptionNew
                          context:nil];//监听avPlayerItem status属性
        [avPlayerItem addObserver:self
                       forKeyPath:PlayerItemLoadedTimeRanges
                          options:NSKeyValueObservingOptionNew
                          context:nil];//监听avPlayerItem loadedTimeRanges属性
    }else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:avPlayerItem];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:avPlayerItem];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:avPlayerItem];
        
        [avPlayerItem removeObserver:self forKeyPath:PlayerItemStatus context:nil];
        [avPlayerItem removeObserver:self forKeyPath:PlayerItemLoadedTimeRanges context:nil];
    }
}

//为了解决加了截图功能后，在8.x及以下系统上退到后台再进入应用视频黑屏有声音的问题
- (void)gotoBackground
{
    if (playerItemVideoOutput) {
        [avPlayerItem removeOutput:playerItemVideoOutput];
        playerItemVideoOutput = nil;
    }
    [super gotoBackground];
}

- (void)fromBackground
{
    if (!playerItemVideoOutput) {
        playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] init];
        [avPlayerItem addOutput:playerItemVideoOutput];
    }
    [super fromBackground];
}

#pragma mark - UIApplication Delegate -

- (void)setPlayUrl:(NSString *)playUrl
{
    //Player已经关闭，就不能在设置URL了
    if (isClose)
        return;
    
    if (avPlayerItem)
        [self addOrRemoveNotification:NO];
    
    playUrl = [playUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (playUrl.length > 0)
    {
        //设置默认值为-1
        nowPlayedTime = -1;
        
        avPlayerItem = [[AVPlayerItem alloc] initWithAsset:[AVAsset assetWithURL:[NSURL URLWithString:playUrl]]];
        playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] init];
        [avPlayerItem addOutput:playerItemVideoOutput];
        
        if (!avPlayer)
        {
            avPlayer = [[AVPlayer alloc] initWithPlayerItem:avPlayerItem];
            
            playerLayer = [AVPlayerLayer playerLayerWithPlayer:avPlayer];
            playerLayer.frame = playerView.layer.bounds;
            playerLayer.videoGravity = AVLayerVideoGravityResize;
            [playerView.layer addSublayer:playerLayer];
            
            //为了手机静音模式下视频也能播放出声音
            AVAudioSession *audioSession = [AVAudioSession sharedInstance];
            [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
            //
        }else
            [avPlayer replaceCurrentItemWithPlayerItem:avPlayerItem];
        
        [self addOrRemoveNotification:YES];
        
        if ([timeoutTimer isValid]) {
            [timeoutTimer invalidate];
            timeoutTimer = nil;
        }
        timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:kVideoRequestTimeoutSecond
                                                        target:self
                                                      selector:@selector(videoRequestTimeout)
                                                      userInfo:nil
                                                       repeats:NO];
    }else
    {
        [self cancel];
        avPlayerItem = nil;
        
        [self updateVideoStateToTheCaller:TD_PLAYER_STATE_FAILED];
    }
}

- (void)setPlayerViewFrame:(CGRect)frame
{
    playerView.frame = frame;
    playerLayer.frame = playerView.layer.bounds;
}

- (void)videoRequestTimeout
{
    [self cancel];//重要，因为设置的超时时间到了，但是有可能系统播放器的超时时间还未到，此时应该取消播放器
    [self updateVideoStateToTheCaller:TD_PLAYER_STATE_ERROR];
}

- (void)updateVideoStateToTheCaller:(TD_PLAYER_STATE)playerState
{
    //把超时timer停止，因为视频状态已有响应
    if ([timeoutTimer isValid]) {
        [timeoutTimer invalidate];
        timeoutTimer = nil;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(showPlayerState:)])
        [self.delegate showPlayerState:playerState];
    
    switch (playerState) {
        case TD_PLAYER_STATE_START_BUFFER:
            self.isBufferLoading = YES;
            break;
        case TD_PLAYER_STATE_END_BUFFER:
            self.isBufferLoading = NO;
            break;
        case TD_PLAYER_STATE_PLAYING:
            if (retryCountdownTimes != self.retryTimes) {
                retryCountdownTimes = self.retryTimes;
            }
            break;
        case TD_PLAYER_STATE_FAILED:
        case TD_PLAYER_STATE_ERROR:
            if (retryCountdownTimes > 0) {
                retryCountdownTimes--;
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(showPlayerState:)])
                    [self.delegate showPlayerState:TD_PLAYER_STATE_RETRY];
            }
            break;
        default:
            break;
    }
}

#pragma mark - Notification -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    AVPlayerItem *_playerItem = (AVPlayerItem *)object;
    if (![_playerItem isEqual:avPlayerItem]) return;
    
    if ([keyPath isEqualToString:PlayerItemStatus])
    {
        if ([_playerItem status] == AVPlayerStatusReadyToPlay)
        {
            [self updateVideoStateToTheCaller:TD_PLAYER_STATE_READY];
            
            self.isPlaying = NO;
            [self monitoringPlayback:_playerItem];//监听播放状态
        }else if ([_playerItem status] == AVPlayerStatusFailed)
        {
            [self updateVideoStateToTheCaller:TD_PLAYER_STATE_FAILED];
        }else
        {
            [self updateVideoStateToTheCaller:TD_PLAYER_STATE_ERROR];
        }
    }else if ([keyPath isEqualToString:PlayerItemLoadedTimeRanges])
    {
        NSTimeInterval bufferTime = [self availableDuration];//计算缓冲进度
        if (!isnan(bufferTime) && self.duration > 0) {
            //更新进度条
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoCurrentProgress:)])
                [self.delegate videoCurrentProgress:bufferTime/self.duration];
            
            //当前缓冲时间大于播放时间多5秒时，就缓冲结束
            if (bufferTime > (self.currentTime+5.f) && self.isBufferLoading) {
                [self updateVideoStateToTheCaller:TD_PLAYER_STATE_END_BUFFER];
            }
        }
    }
}

- (NSTimeInterval)availableDuration
{
    NSArray *loadedTimeRanges = [avPlayerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];//获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    if (isnan(startSeconds)) {
        //显示加载圈
        [self updateVideoStateToTheCaller:TD_PLAYER_STATE_START_BUFFER];
    }
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;//计算缓冲总进度
    return result;
}

- (void)monitoringPlayback:(AVPlayerItem *)_playerItem
{
    if (playbackTimeObserver)
        [avPlayer removeTimeObserver:playbackTimeObserver];
    
    __weak __typeof(self)weakSelf = self;
    playbackTimeObserver = [avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                                  queue:NULL
                                                             usingBlock:^(CMTime time)
                            {
                                NSInteger currentTime = (NSInteger)CMTimeGetSeconds(_playerItem.currentTime);
                                if (nowPlayedTime != currentTime) {
                                    nowPlayedTime = currentTime;
                                    
                                    //如果还是缓冲状态就结束缓冲
                                    if (weakSelf.isBufferLoading) {
                                        [weakSelf updateVideoStateToTheCaller:TD_PLAYER_STATE_END_BUFFER];
                                    }
                                    
                                    //保证TD_PLAYER_STATE_PLAYING只被传出一次
                                    if (!weakSelf.isPlaying && avPlayer.rate) {
                                        weakSelf.isPlaying = YES;
                                        [weakSelf updateVideoStateToTheCaller:TD_PLAYER_STATE_PLAYING];
                                    }
                                    
                                    NSInteger currentSecond = 0;
                                    if (!weakSelf.isLive)
                                        currentSecond = currentTime;//计算当前在第几秒
                                    if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(videoCurrentPlayTime:)]) {
                                        [weakSelf.delegate videoCurrentPlayTime:currentSecond];
                                    }
                                }
                            }];
}

- (void)moviePlayStalled:(NSNotification *)notifcation
{
    self.isPlaying = NO;
    [self updateVideoStateToTheCaller:TD_PLAYER_STATE_START_BUFFER];
}

- (void)moviePlayDidEnd:(NSNotification *)notifcation
{
    self.isPlaying = NO;
    [self updateVideoStateToTheCaller:TD_PLAYER_STATE_FINISH];
}

- (void)moviePlayError:(NSNotification *)notifcation
{
    self.isPlaying = NO;
    [self updateVideoStateToTheCaller:TD_PLAYER_STATE_ERROR];
}

#pragma mark - 父类外部调用接口 -

- (void)play
{
    [avPlayer play];
}

- (void)pause
{
    self.isPlaying = NO;
    [avPlayer pause];
    [self updateVideoStateToTheCaller:TD_PLAYER_STATE_PAUSE];
}

- (void)stop
{
    self.isPlaying = NO;
    [avPlayer pause];
    [self updateVideoStateToTheCaller:TD_PLAYER_STATE_STOP];
}

- (void)replay
{
    [avPlayer replaceCurrentItemWithPlayerItem:avPlayerItem];
    [avPlayer play];
    
    if ([timeoutTimer isValid]) {
        [timeoutTimer invalidate];
        timeoutTimer = nil;
    }
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:kVideoRequestTimeoutSecond
                                                    target:self
                                                  selector:@selector(videoRequestTimeout)
                                                  userInfo:nil
                                                   repeats:NO];
}

- (void)cancel
{
    self.isPlaying = NO;
    
    [avPlayer pause];
    [avPlayerItem.asset cancelLoading];
    [avPlayer replaceCurrentItemWithPlayerItem:nil];
    
    //把超时timer停止，因为已取消播放器
    if ([timeoutTimer isValid]) {
        [timeoutTimer invalidate];
        timeoutTimer = nil;
    }
}

- (void)seekToTime:(CGFloat)seekTime
{
    //页面已经退出，不需要再设置
    if (isClose)
        return;
    
    //拖动就显示缓冲
    [self updateVideoStateToTheCaller:TD_PLAYER_STATE_START_BUFFER];
    
    if (seekTime < 0)
        seekTime = 0;
    if (seekTime >= CMTimeGetSeconds(avPlayerItem.duration))
        seekTime = CMTimeGetSeconds(avPlayerItem.duration)-10.f;
    
    CMTime changedTime = CMTimeMakeWithSeconds(seekTime, 1);
    [avPlayer seekToTime:changedTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        [self updateVideoStateToTheCaller:TD_PLAYER_STATE_START_BUFFER];
        [avPlayer play];
    }];
}

- (NSString *)getNetworkSpeed
{
    if (cacheArrayCount != avPlayer.currentItem.accessLog.events.count)
    {
        beforeCacheSize = 0.f;
        cacheArrayCount = avPlayer.currentItem.accessLog.events.count;
    }
    
    NSArray *events = avPlayer.currentItem.accessLog.events;
    NSInteger count = events.count;
    for (int i = 0; i < count; i++)
    {
        if (i == count - 1) {
            AVPlayerItemAccessLogEvent *currentEvent = [events objectAtIndex:i];
            long long byte = currentEvent.numberOfBytesTransferred;
            
            CGFloat changedByte = (CGFloat)byte;
            if (beforeCacheSize >= 0 && changedByte > beforeCacheSize) {
                CGFloat networkSpeed = changedByte-beforeCacheSize;
                NSString *unit = @"KB";
                CGFloat changedSpeed = networkSpeed/1024.0/8.f;
                if (networkSpeed < 1024.f) {
                    changedSpeed = networkSpeed/8.f;
                    unit = @"B";
                }else
                {
                    if (changedSpeed >= 1024.f) {
                        changedSpeed = changedSpeed/1024.0;
                        unit = @"M";
                    }
                }
                
                nowNetworkSpeed = [NSString stringWithFormat:@"%.1f %@/s", changedSpeed, unit];
            }
            beforeCacheSize = changedByte;
        }
    }
    
    return nowNetworkSpeed;
}

- (UIImage *)getScreenshot
{
    if (!playerItemVideoOutput) {
        return nil;
    }
    
    CMTime itemTime = avPlayerItem.currentTime;
    CVPixelBufferRef pixelBuffer = [playerItemVideoOutput copyPixelBufferForItemTime:itemTime itemTimeForDisplay:nil];
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
                             createCGImage:ciImage
                             fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
    
    UIImage *frameImg = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    return frameImg;
}

- (void)close
{
    [super close];
    
    isClose = YES;
    [self cancel];
}

#pragma mark - dealloc -

- (void)dealloc
{
    if (avPlayerItem)
        [self addOrRemoveNotification:NO];
    if (playbackTimeObserver)
        [avPlayer removeTimeObserver:playbackTimeObserver];
}

@end
