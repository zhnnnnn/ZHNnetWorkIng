//
//  ZHNbaseNetWrok+test.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "DDbaseNetWork+test.h"


@implementation DDbaseNetWork (test)

- (NSNumber *)zhn_getAllBarsWithControl:(NSObject *)control
                                Success:(successBlock)success
                                failure:(failureBlock)failure{
    
    // 请求参数
    DDnetWrokEngine * workEngine = [[DDnetWrokEngine alloc]init];
//    workEngine.requestURL = @"http://139.196.197.21:8080/Hotcity/api/v1/bars";
    workEngine.requestURL = @"http://gamma-member.tesir.top/api/member/app/getAppPointPrivilege?access_token=qdesB4OvQJYAAAAAAAA-25KD0c5Fu-w_";
//    workEngine.requestURL = @"http://gamma-uaa.tesir.top/uaa/obtainToken";
//    workEngine.params = @{
//        @"username": @"15988147956",
//        @"password": @"test123456"
//    };
    workEngine.requestType = DDrequestTypeGET;
//    workEngine.cacheType = DDcacheTypeNetCache;
//    workEngine.cacheTime = 20;
    workEngine.success = success;
    workEngine.failure = failure;
    workEngine.control = control;
    
    // 发送请求
    return  [self callRequestWithWorkEngnine:workEngine];
}

- (NSNumber *)getSMScodeSuccess:(successBlock)success
                        failure:(failureBlock)failure {
    // 请求参数
    DDnetWrokEngine * workEngine = [[DDnetWrokEngine alloc]init];
        workEngine.requestURL = @"http://139.196.197.21:8080/Hotcity/api/v1/bars";
    workEngine.requestType = DDrequestTypeGET;
    workEngine.success = success;
    workEngine.failure = failure;
    
    // 发送请求
    return  [self callRequestWithWorkEngnine:workEngine];
}


- (void)zhn_downLoadUrl:(NSString *)dataUrl
               progress:(progressBlcok)progress
               complete:(downLoadCompleteBlock)complete
                failure:(downLoadErrorBlock)failure
          downLoadState:(downLoadStatesBlock)downLoadState{
    
    // 下载路径
    NSString * fullUrl = dataUrl;
    
    // 下载参数
    DDdownLoadnetWorkEngine * downLoadEngnine = [[DDdownLoadnetWorkEngine alloc]init];
    downLoadEngnine.fullDownLoadUrl = fullUrl;
    downLoadEngnine.progress = progress;
    downLoadEngnine.complete = complete;
    downLoadEngnine.failure = failure;
    downLoadEngnine.downLoadState = downLoadState;
    
    [self downloadRequestWithDownloadWorkEngnine:downLoadEngnine];
}






@end
