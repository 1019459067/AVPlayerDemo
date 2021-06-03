//
//  VideoPlayer.m
//  AVPlayerDemo
//
//  Created by HN on 2021/6/1.
//

#import "VideoPlayer.h"

@interface VideoPlayer ()

@property (nonatomic, strong) UIImageView *thumbImageView;
/// 帧图片
@property (strong, nonatomic) UIImage *frameImage;

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (nonatomic) id observer;

@property (nonatomic, assign) CGFloat curruntVolumeValue; /// 记录系统声音
@property (assign, nonatomic, getter=isActiving) BOOL bActive;
@property (assign, nonatomic, readwrite) NSInteger width;
@property (assign, nonatomic, readwrite) NSInteger height;
@property (assign, nonatomic) float rate;
@end

@implementation VideoPlayer

- (void)dealloc {
    [self removeObserverForSystem];
    [self reset];
    [self.player removeTimeObserver:self.observer];
}

#pragma mark - life
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initValue];
        self.backgroundColor = UIColor.clearColor;
        
        [self addSubview:self.thumbImageView];
        [self addObserverForSystem];
    }
    return self;
}

- (void)initValue {
    self.contentMode = VideoRenderModeAspectFit;
    self.bActive = YES;
    self.autoPlayCount = 0;
    self.rate = 1;
}

- (void)reset {
    [self removeObserverForPlayer];
    
    // If set 'self.playerLayer.player = nil' or 'self.player = nil', can not cancel observeing of 'addPeriodicTimeObserverForInterval'.
    [self.player pause];
    self.playerItem = nil;
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;

    self.playerStatus = VideoPlayerStatusFinished;
}

#pragma mark - private

- (void)videoJumpWithScale:(float)scale {
    CMTime startTime = CMTimeMakeWithSeconds(scale, self.player.currentTime.timescale);
    
    if (CMTIME_IS_INDEFINITE(startTime) || CMTIME_IS_INVALID(startTime)) return;
    
    [self.player seekToTime:startTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self startPlay];
}

- (void)preparPlay {
    if (!self.playerLayer) {
        self.playerStatus = VideoPlayerStatusReady;
        
        NSArray *tracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
        if([tracks count] > 0) {
            AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
            self.width = videoTrack.naturalSize.width;
            self.height = videoTrack.naturalSize.height;
        }
        
        self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset];
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        [self.layer insertSublayer:self.playerLayer above:self.thumbImageView.layer];

        self.curruntVolumeValue = self.player.volume;

        [self addObserverForPlayer];
    } else {
        self.playerStatus = VideoPlayerStatusPlaying;

        [self videoJumpWithScale:0];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    if (self.contentMode == VideoRenderModeScaleToFill) {
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.thumbImageView.contentMode = UIViewContentModeScaleAspectFill;
    } else if (self.contentMode == VideoRenderModeAspectFit) {
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.thumbImageView.contentMode = UIViewContentModeScaleAspectFit;
    } else if (self.contentMode == VideoRenderModeAspectFill) {
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.thumbImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
}

- (void)startPlay {
    if (self.player) {
        [self.player play];
        self.player.rate = self.rate;
        self.playerStatus = VideoPlayerStatusPlaying;
    }
}

- (void)endPlayWithNeedAutoPlay:(BOOL)bNeed {
    if (self.player) {
        self.playerStatus = VideoPlayerStatusFinished;
        
        if (bNeed) {
            [self autoPlay];
        } else {
            [self.player removeTimeObserver:self.observer];
            [self reset];
        }
        
        if ([self.delegate respondsToSelector:@selector(videoPlayerFinished:)]) {
            [self.delegate videoPlayerFinished:self];
        }
        
        NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.currentTime);
        NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
        
        if ([self.delegate respondsToSelector:@selector(videoPlayer:duration:currentTime:)]) {
            [self.delegate videoPlayer:self duration:duration>=0?duration:0 currentTime:currentTime];
        }
    }
}

- (void)finishPlay {
    [self endPlayWithNeedAutoPlay:YES];
}

- (void)playerStop {
    if (self.player) {
        [self endPlayWithNeedAutoPlay:NO];
    }
}

- (void)playerPause {
    if (self.player) {
        [self.player pause];
        
        if ([self.delegate respondsToSelector:@selector(videoPlayerPaused:)]) {
            [self.delegate videoPlayerPaused:self];
        }
    }
}

- (void)playerResume {
    if (self.player) {
        [self startPlay];
    }
}

- (void)autoPlay {
    if (self.autoPlayCount == NSUIntegerMax) {
        [self preparPlay];
    } else if (self.autoPlayCount > 0) {
        --self.autoPlayCount;
        [self preparPlay];
    }
}

#pragma mark - observe

- (void)addObserverForPlayer {
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    __weak typeof(self) wSelf = self;
    self.observer = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1000.0)
                                                              queue:dispatch_get_main_queue()
                                                         usingBlock:^(CMTime time) {
//        __strong typeof(self) sSelf = wSelf;
        NSArray *loadedRanges = wSelf.player.currentItem.seekableTimeRanges;
        if (loadedRanges.copy > 0) {
//            if (sSelf.player) {
//                sSelf.player.rate = sSelf.rate;
//            }
            
            wSelf.thumbImageView.hidden = YES;
            
            NSTimeInterval currentTime = CMTimeGetSeconds(wSelf.player.currentItem.currentTime);
            NSTimeInterval duration = CMTimeGetSeconds(wSelf.player.currentItem.duration);

            if ([wSelf.delegate respondsToSelector:@selector(videoPlayer:duration:currentTime:)]) {
                [wSelf.delegate videoPlayer:wSelf duration:duration>=0?duration:0 currentTime:currentTime];
            }
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
}

- (void)removeObserverForPlayer {
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object == self.playerItem) {
        if ([keyPath isEqualToString:@"status"]) {
            [self playerItemStatusChanged];
        }
    }
}

- (void)didPlayToEndTime:(NSNotification *)noti {
    if (noti.object == self.playerItem) {
        [self finishPlay];
    }
}

- (void)playerItemStatusChanged {
    if (!self.isActiving) return;
    
    switch (self.playerItem.status) {
        case AVPlayerItemStatusReadyToPlay: {
            // Delay to update UI.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self startPlay];
//                double max = CMTimeGetSeconds(self.playerItem.duration);
            });
        }
            break;
        case AVPlayerItemStatusUnknown: {
            self.playerStatus = VideoPlayerStatusFailed;
            [self reset];
        }
            break;
        case AVPlayerItemStatusFailed: {
            self.playerStatus = VideoPlayerStatusFailed;
            [self reset];
        }
            break;
    }
}

- (void)removeObserverForSystem {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)addObserverForSystem {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarFrame) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:)   name:AVAudioSessionRouteChangeNotification object:nil];
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    self.bActive = NO;
    [self playerPause];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    self.bActive = YES;
    [self startPlay];
}

//- (void)didChangeStatusBarFrame {
//    [self playerPause];
//}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *interuptionDict = notification.userInfo;
        NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
        switch (routeChangeReason) {
            case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
                [self playerPause];
                break;
        }
    });
}

#pragma mark - set data
- (void)setFrameImage:(UIImage *)frameImage {
    _frameImage = frameImage;
    
    self.thumbImageView.hidden = NO;
    self.thumbImageView.image = frameImage;
    self.thumbImageView.frame = self.bounds;
}

- (void)setContentMode:(VideoRenderMode)contentMode {
    _contentMode = contentMode;
}

#pragma mark - get data
- (UIImageView *)thumbImageView {
    if (!_thumbImageView) {
        _thumbImageView = [UIImageView new];
        _thumbImageView.layer.masksToBounds = YES;
    }
    return _thumbImageView;
}

#pragma mark ---- 获取图片第一帧
- (void)getFirstFrameWithVideoWithAsset:(AVAsset *)asset
                                  block:(void(^)(UIImage *image))block
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        assetGen.appliesPreferredTrackTransform = YES;
        CMTime time = CMTimeMakeWithSeconds(0.0, 600);
        NSError *error = nil;
        CMTime actualTime;
        CGImageRef image = [assetGen copyCGImageAtTime:time
                                            actualTime:&actualTime
                                                 error:&error];
        UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
        CGImageRelease(image);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.thumbImageView.image = videoImage;
            if (block) {
                block(videoImage);
            }
        });
    });
}

- (void)setRate:(float)rate {
    _rate = rate;
}

- (BOOL)startPlay:(NSString *)url {
//    if (url.length == 0) {
//        return NO;
//    }
//    NSTimeInterval t11 = CFAbsoluteTimeGetCurrent();
//    AVURLAsset *videoAVAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:url] options:nil];
//    NSTimeInterval t21 = CFAbsoluteTimeGetCurrent();
//    NSLog(@"time1: %f", t21-t11);
//
//    if (videoAVAsset == nil) {
//        return NO;
//    }
//    self.asset = videoAVAsset;
    return YES;
}

@end
