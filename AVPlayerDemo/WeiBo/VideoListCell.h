//
//  VideoListCell.h
//  AVPlayerDemo
//
//  Created by HN on 2021/6/30.
//

#import <UIKit/UIKit.h>
#import "VideoPlayer.h"
#import "VideoInfo.h"

@class VideoListCell;
@protocol VideoListCellDelegate <NSObject>
@optional
- (void)playButtonClick:(UIButton *)sender;
@end

@interface VideoListCell : UITableViewCell
@property(weak, nonatomic) IBOutlet UIView *videoBackView;

@property(nonatomic, assign) NSInteger row;
@property(strong, nonatomic) VideoInfo *model;

@property(weak, nonatomic) id<VideoListCellDelegate> delegate;

@property(nonatomic, strong) VideoPlayer *player;

- (void)shouldToPlay;

@end
