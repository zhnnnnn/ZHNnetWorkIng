//
//  ZHNbaseNetWrok+test.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "ZHNbaseNetWrok+test.h"


@implementation ZHNbaseNetWrok (test)

- (NSNumber *)zhn_getAllBarsWithControl:(NSObject *)control
                                Success:(successBlock)success
                                failure:(errorBlock)failure{
    
    // 请求的路径
    NSString * fullUrlString = [NSString stringWithFormat:@"%@%@",self.baseURL,@"bars"];
    
    // 请求参数
    ZHNnetWrokEngnine * worlEngine = [[ZHNnetWrokEngnine alloc]init];
    worlEngine.requestURL = fullUrlString;
    worlEngine.requestType = ZHNrequestTypeGET;
    worlEngine.params = nil;
    worlEngine.cacheTime = 1000;
    worlEngine.success = success;
    worlEngine.failure = failure;
    
    // 发送请求
    return  [self callRequestWithWorkEngnine:worlEngine];
}

- (void)zhn_downLoadUrl:(NSString *)dataUrl
               progress:(progressBlcok)progress
               complete:(downLoadCompleteBlock)complete
                failure:(downLoadErrorBlock)failure
          downLoadState:(downLoadStatesBlock)downLoadState{
    
    // 下载路径
    NSString * fullUrl = dataUrl;
    
    // 下载参数
    ZHNdownLoadnetWorkEngnine * downLoadEngnine = [[ZHNdownLoadnetWorkEngnine alloc]init];
    downLoadEngnine.fullDownLoadUrl = fullUrl;
    downLoadEngnine.progress = progress;
    downLoadEngnine.complete = complete;
    downLoadEngnine.failure = failure;
    downLoadEngnine.downLoadState = downLoadState;
    
    [self downloadRequestWithDownloadWorkEngnine:downLoadEngnine];
}

@end
