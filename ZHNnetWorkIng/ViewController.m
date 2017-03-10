//
//  ViewController.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/12.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "ViewController.h"
#import "DDbaseNetWork+test.h"
#import <AFNetworking.h>
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIProgressView *downLoadingProgressView;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (nonatomic,assign) ZHNdownLoadState downLoadState;
@end

static  NSString * downloadingUrl = @"http://baobab.wdjcdn.com/1456459181808howtoloseweight_x264.mp4";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction)];
    [self.view addGestureRecognizer:tap];
}

- (void)tapAction {
    [DDNetWorkManager zhn_getAllBarsWithControl:self Success:^(id result, DDcacheType cacheType, DDresultType resultType) {
        NSString *resultString = [[NSString alloc]initWithData:result encoding:NSUTF8StringEncoding];
        NSLog(@"%@",resultString);
//        NSLog(@"缓存类型%ld",(long)cacheType);
//        NSLog(@"数据类型%ld",(long)resultType);
    } failure:^(NSError *error) {
        NSLog(@"%ld",error.code);
    }];
}

- (void)p_downLoadDatas{
    
    [[DDbaseNetWork shareInstance]zhn_downLoadUrl:downloadingUrl progress:^(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress) {
        // 如果你的下载控制是跨层的（类似优酷之类的视频软件下载完之后暂停下载删除之类的是在设置模块里面的）用notification来处理
        NSLog(@"current ==  %ld total == %ld progress == %f",receivedSize,expectedSize,progress);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downLoadingProgressView.progress = progress;
        });
    } complete:^(NSString *cachedPath) {
        NSLog(@"下载完成了 path=>%@",cachedPath);
    } failure:^(NSError *error) {
        
    } downLoadState:^(ZHNdownLoadState downLoadState) {
        
        switch (downLoadState) {
            case ZHNdownLoadStateStart:
            {
                [self.actionButton setTitle:@"暂停" forState:UIControlStateNormal];
            }
                break;
            case ZHNdownLoadStatePause:
            {
                [self.actionButton setTitle:@"开始" forState:UIControlStateNormal];
            }
                break;
            case ZHNdownLoadStateCompleted:
            {
                // ui要放在主线程刷新（下载操作是多线程这里不放在主线程刷新会有问题）
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.actionButton setTitle:@"已完成" forState:UIControlStateNormal];
                });
            }
                break;
            default:
                break;
        }
    }];
    
}

- (IBAction)action:(id)sender {
   
    [self p_downLoadDatas];
}
- (IBAction)deleteAction:(id)sender {
    [[DDbaseNetWork shareInstance]deleteCachedDataWithUrlString:downloadingUrl];
    self.downLoadingProgressView.progress = 0;
    [self.actionButton setTitle:@"开始" forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
