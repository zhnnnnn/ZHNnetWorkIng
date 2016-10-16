//
//  ZHNbaseNetWrok.h
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/12.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHNnetWrokEngnine.h"

@interface ZHNbaseNetWrok : NSObject


/**
 单例的初始化方法

 @return 实例
 */
+ (instancetype)shareInstance;


/**
 初始化配置一些数据

 @param baseURL 网络接口的基础url（一般接口都是前面的基础url都是一样的）
 @param needLog 是否需要打印
 */
- (void)configBaseNetWorkWithBaseUrl:(NSString *)baseURL needLogParams:(BOOL)needLog;

/**
 基础发起请求方法

 @param workEngine 请求对象

 @return 请求的id
 */
- (NSNumber *)callRequestWithWorkEngnine:(ZHNnetWrokEngnine *)workEngine;

/**
 取消网络请求

 @param requestID 网络请求的id
 */
- (void)cancleRequsetWithRequsetID:(NSNumber *)requestID;

// 基础的url
@property (nonatomic,copy,readonly) NSString * baseURL;

@end
