//
//  VideoPageViewController.m
//  AVPlayerDemo
//
//  Created by HN on 2021/6/4.
//

#import "VideoPageViewController.h"
#import "PlayerContentViewController.h"

@interface VideoPageViewController () <UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate>
// QHPageViewController
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (strong, nonatomic) UIScrollView *scrollView;

@end

@implementation VideoPageViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // 设置UIPageViewController的配置项
//    NSDictionary *options = @{UIPageViewControllerOptionInterPageSpacingKey : @(20)};
    NSDictionary *options = @{UIPageViewControllerOptionSpineLocationKey : @(UIPageViewControllerSpineLocationNone)};

    // 根据给定的属性实例化UIPageViewController
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                          navigationOrientation:UIPageViewControllerNavigationOrientationVertical
                                                                        options:options];
    // 设置UIPageViewController代理和数据源
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    
    // 设置UIPageViewController初始化数据, 将数据放在NSArray里面
    // 如果 options 设置了 UIPageViewControllerSpineLocationMid,注意viewControllers至少包含两个数据,且 doubleSided = YES
    
    PlayerContentViewController *initialViewController = [self viewControllerAtIndex:0];// 得到第一页
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    [self.pageViewController setViewControllers:viewControllers
                              direction:UIPageViewControllerNavigationDirectionReverse
                               animated:NO
                             completion:nil];

    // 设置UIPageViewController 尺寸
    self.pageViewController.view.frame = self.view.bounds;

    // 在页面上，显示UIPageViewController对象的View
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];

    self.scrollView = [self findScrollView];
    self.scrollView.delegate = self;
}

#pragma mark - other
- (IBAction)onActionBack:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIScrollView *)findScrollView {
    for (UIView *view in self.pageViewController.view.subviews) {
        if (![view isKindOfClass:[UIScrollView class]]) continue;
        UIScrollView *scrollView = (UIScrollView *)view;
        scrollView.tag = 1000;
        return scrollView;
    }
    return nil;
}

#pragma mark 根据index得到对应的UIViewController
- (PlayerContentViewController *)viewControllerAtIndex:(NSUInteger)index {
    if ((self.urlsArray.count == 0) || (index >= self.urlsArray.count)) {
        return nil;
    }
    // 创建一个新的控制器类，并且分配给相应的数据
    PlayerContentViewController *contentVC = [[PlayerContentViewController alloc] init];
    contentVC.index = index;
    contentVC.url = self.urlsArray[contentVC.index];
    return contentVC;
}

#pragma mark 数组元素值，得到下标值
- (NSUInteger)indexOfViewController:(PlayerContentViewController *)viewController {
    return viewController.index;
}

#pragma mark - UIPageViewControllerDataSource、
// 向前翻页展示的ViewController
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {

    NSUInteger index = [self indexOfViewController:(PlayerContentViewController *)viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    index--;
    // 返回的ViewController，将被添加到相应的UIPageViewController对象上。
    // UIPageViewController对象会根据UIPageViewControllerDataSource协议方法,自动来维护次序
    // 不用我们去操心每个ViewController的顺序问题
    return [self viewControllerAtIndex:index];
    
}

// 向后翻页展示的ViewController
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(PlayerContentViewController *)viewController];
    if (index == NSNotFound) {
        return nil;
    }
    index++;
    if (index == self.urlsArray.count) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

#pragma mark - UIPageViewControllerDelegate
// 翻页视图控制器将要翻页时执行的方法
- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(nonnull NSArray<UIViewController *> *)pendingViewControllers
{
    
}

// 翻页动画执行完成后回调的方法
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed;
{
    self.scrollView.userInteractionEnabled = YES;
    
    if (completed == NO) return;
    PlayerContentViewController *playerController = nil;
    if (previousViewControllers.count) {
        playerController = (PlayerContentViewController *)[previousViewControllers lastObject];
    }
//    if (playerController.videoPlayer) {
//        if (playerController.videoPlayer.status != VideoPlayerStatusPlaying) {
////            playerController.textView.text = self.url;
//            [playerController.videoPlayer playerStop];
//        }
//    }
//    [playerController.videoPlayer playerStart];
}

// 屏幕防线改变时回到的方法，可以通过返回值重设书轴类型枚举
//- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
//
//}

#pragma mark - UIPageViewControllerDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView.isDragging) {
//        scrollView.userInteractionEnabled = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

@end
