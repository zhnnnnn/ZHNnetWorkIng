//
//  ZHNbaseNetWrok.h
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/12.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHNnetWrokEngnine.h"
#import "ZHNdownLoadnetWorkEngnine.h"

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

// 服务器基础路径
@property (nonatomic,copy,readonly) NSString * baseURL;


//=================普通的请求==========================//
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


//==================下载请求=================================//

/**
 下载网络请求（如果请求在调用会暂停 如果请求暂停会开始调用）
 
 @param workEngine 请求信息和回调
 */
- (void)downloadRequestWithDownloadWorkEngnine:(ZHNdownLoadnetWorkEngnine *)workEngine;

/**
 url对应文件的大小(需要调用downloadRequestWithDownloadWorkEngnine之后才能拿到值)

 @param urlString 网络资源路径

 @return 文件大小
 */
- (NSInteger)fileTotalLength:(NSString *)urlString;

/**
 下载的文件对应的大小

 @param urlString 网络资源路径

 @return 下载文件的大小
 */
- (NSInteger)downLoadedFileLength:(NSString *)urlString;

/**
 文件是否下载完成

 @param urlString 网络资源路径

 @return 是否下载完成
 */
- (BOOL)isCompleteDownLoaded:(NSString *)urlString;

/**
 删除本地下载的文件

 @param uslString 网络资源路径
 */
- (void)deleteCachedDataWithUrlString:(NSString *)uslString;

/**
 删除所有的文件
 */
- (void)deleteAllCachedDatas;


@end
