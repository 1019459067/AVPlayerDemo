//
//  DYVideoListCell.m
//  AVPlayerDemo
//
//  Created by HN on 2021/6/30.
//

#import "UIImageView+WebCache.h"
#import "Utility.h"
#import "DYVideoListCell.h"
#import "SDImageCache.h"

@interface DYVideoListCell () <VideoPlayerDelegate>
@property(weak, nonatomic) IBOutlet UIImageView *preImageView;
@property(weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIView *playerStatusBar;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewConstraintB;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *playerStatusBarConstraintB;

/// 视频宽度
@property(assign, nonatomic) CGFloat videoWidth;
/// 视频高度
@property(assign, nonatomic) CGFloat videoHeight;

@end

@implementation DYVideoListCell

- (void)dealloc {
    NSLog(@"%s",__func__);
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.videoBackView.userInteractionEnabled = YES;
    self.videoBackView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

- (void)shouldToPlay {
    if (self.model.type == VideoInfoTypeVideo) {
        [self.videoBackView addSubview:self.player];
        if (self.model.playTime) {
            [self.player seekToTimeTo:self.model.playTime];
        }

        self.player.frame = CGRectMake(0, 0, self.videoBackView.frame.size.width, self.videoBackView.frame.size.height);
    }
}

- (void)shouldToStop {
    [self.player stop];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (@available(iOS 11.0, *)) {
        self.textViewConstraintB.constant = self.safeAreaInsets.bottom+44;
        self.playerStatusBarConstraintB.constant = self.safeAreaInsets.bottom+42;
    } else {
        self.textViewConstraintB.constant = 44;
        self.playerStatusBarConstraintB.constant = 42;
    }
}

//加载动画
- (void)startLoadingPlayItemAnim:(BOOL)isStart {
    if (isStart) {
        self.playerStatusBar.backgroundColor = UIColor.whiteColor;
        [self.playerStatusBar setHidden:NO];
        [self.playerStatusBar.layer removeAllAnimations];
        
        CAAnimationGroup *animationGroup = [[CAAnimationGroup alloc]init];
        animationGroup.duration = 0.5;
        animationGroup.beginTime = CACurrentMediaTime();
        animationGroup.repeatCount = MAXFLOAT;
        animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        CABasicAnimation * scaleAnimation = [CABasicAnimation animation];
        scaleAnimation.keyPath = @"transform.scale.x";
        scaleAnimation.fromValue = @(1.0f);
        scaleAnimation.toValue = @(1.0f * [UIScreen mainScreen].bounds.size.width);
        
        CABasicAnimation * alphaAnimation = [CABasicAnimation animation];
        alphaAnimation.keyPath = @"opacity";
        alphaAnimation.fromValue = @(1.0f);
        alphaAnimation.toValue = @(0.5f);
        [animationGroup setAnimations:@[scaleAnimation, alphaAnimation]];
        [self.playerStatusBar.layer addAnimation:animationGroup forKey:nil];
    } else {
        [self.playerStatusBar.layer removeAllAnimations];
        [self.playerStatusBar setHidden:YES];
    }
}

#pragma mark - other
- (BOOL)isVideoPortrait:(CGAffineTransform)t {
    BOOL isPortrait = NO;
    // Portrait
    if (t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) {
        isPortrait = YES;
    }
    // PortraitUpsideDown
    if (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) {
        isPortrait = YES;
    }
    // LandscapeRight
    if (t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) {
        isPortrait = NO;
    }
    // LandscapeLeft
    if (t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {
        isPortrait = NO;
    }
    return isPortrait;
}

#pragma mark - VideoPlayerDelegate
- (void)videoPlayer:(VideoPlayer *)videoPlayer playerStatus:(VideoPlayerStatus)status error:(NSError *)error {
    if (status == VideoPlayerStatusUnknown) {
        [self startLoadingPlayItemAnim:YES];
    } else if (status == VideoPlayerStatusReady) {
        [self startLoadingPlayItemAnim:YES];
    } else if (status == VideoPlayerStatusBuffering) {
//        [self startLoadingPlayItemAnim:YES];
    } else if (status == VideoPlayerStatusPlaying) {
        [self startLoadingPlayItemAnim:NO];
    } else if (status == VideoPlayerStatusFailed) {
        [self startLoadingPlayItemAnim:NO];
    } else if (status == VideoPlayerStatusFinished) {
        //
    }
}

#pragma mark - get data
- (VideoPlayer *)player {
    if (!_player) {
        _player = [[VideoPlayer alloc] initWithUrl:[NSURL URLWithString:self.model.videoUrl] delegate:self];
        //设置播放器背景颜色
        _player.backgroundColor = [UIColor clearColor];
        _player.isFullScreenDisplay = YES;
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        NSString *imageUrl = [Utility getFrameImagePathWithVideoPath:self.model.videoUrl];
        NSString *key = [manager cacheKeyForURL:[NSURL URLWithString:imageUrl]];
        SDImageCache *cache = [SDImageCache sharedImageCache];
        //此方法会先从memory中取。
        UIImage *image = [cache imageFromDiskCacheForKey:key];
        if (image) {
            CGFloat width = image.size.width;
            CGFloat height = image.size.height;
            [self setPlayerModeWithWidth:width height:height];
        } else {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
                AVURLAsset *anAsset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:self.model.videoUrl] options:options];
                NSArray *tracks = [anAsset tracksWithMediaType:AVMediaTypeVideo];
                if ([tracks count] > 0) {
                    AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
                    CGFloat width = videoTrack.naturalSize.width;
                    CGFloat height = videoTrack.naturalSize.height;
                    CGAffineTransform t = videoTrack.preferredTransform;//这里的矩阵有旋转角度，转换一下即可
                    if ([self isVideoPortrait:t] == NO) {
                        self.videoHeight = height;
                        self.videoWidth = width;
                    } else {
                        self.videoWidth = height;
                        self.videoHeight = width;
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setPlayerModeWithWidth:self.videoWidth height:self.videoHeight];
                    });
                }
            });
        }
    }
    return _player;
}

#pragma mark - set data
- (void)setPlayerModeWithWidth:(CGFloat)width height:(CGFloat)height {
    if (height / width <= 4 / 3.0) {
        self.player.mode = VideoPlayerGravityResizeAspect;
    } else {
        self.player.mode = VideoPlayerGravityResizeAspectFill;
    }
}

- (void)setModel:(VideoInfo *)model {
    _model = model;
    
    if (model.type == VideoInfoTypeVideo) {
        self.textView.text = model.videoUrl;
    } else {
        self.textView.text = @"我是图片";
    }
    
    __weak typeof(self) weakSelf = self;
    NSString *imageUrl = [Utility getFrameImagePathWithVideoPath:model.videoUrl];
    [self.preImageView sd_setImageWithURL:[NSURL URLWithString:imageUrl] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            CGFloat width = image.size.width;
            CGFloat height = image.size.height;
            if (height / width <= 4 / 3.0) {
                weakSelf.preImageView.contentMode = UIViewContentModeScaleAspectFit;
            } else {
                weakSelf.preImageView.contentMode = UIViewContentModeScaleAspectFill;
            }
        }
    }];
}
@end
