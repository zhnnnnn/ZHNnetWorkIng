//
//  ZHNbaseNetWrok.h
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/12.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDnetWrokEngine.h"
#import "DDdownLoadnetWorkEngine.h"

#define DDNetWorkManager [DDbaseNetWork shareInstance]
typedef void(^DDErrorHandleBlock)(NSError *error);
typedef void(^DDauthorErrorHandleBlock)(NSError *error,DDnetWrokEngine *engine);
@interface DDbaseNetWork : NSObject
/**
 单例的初始化方法

 @return 实例
 */
+ (instancetype)shareInstance;

/**
 基础化配置

 @param errorHandle errorCode的处理
 @param needLog 是否需要打印
 */
- (void)configBaseNetWorkNeedLogParams:(BOOL)needLog
                       errorHandle:(DDErrorHandleBlock)errorHandle;

/**
 接口需要授权的配置

 @param needLog 是否需要打印
 @param normalErrorHandle 普通错误的处理
 @param authorErrorHandle 需要授权的处理
 */
- (void)configBaseNetWorkNeedLogParams:(BOOL)needLog
                 normalErrorHandle:(DDErrorHandleBlock)normalErrorHandle
                     authorErrorHandle:(DDauthorErrorHandleBlock)authorErrorHandle;
//=================普通的请求==========================//
/**
 基础发起请求方法

 @param workEngine 请求对象

 @return 请求的id
 */
- (NSNumber *)callRequestWithWorkEngnine:(DDnetWrokEngine *)workEngine;

/**
 取消网络请求

 @param requestID 网络请求的id
 */
- (void)cancleRequsetWithRequsetID:(NSNumber *)requestID;

/**
 删除某个engine对应的缓存
 
 @param engine 请求engine
 */
- (void)deleteCacheWithWorkEngine:(DDnetWrokEngine *)engine;

/**
 清空普通请求的缓存数据
 */
- (void)deleteAllNormalRequestCaches;




//==================下载请求=================================//
/**
 下载网络请求（如果请求在调用会暂停 如果请求暂停会开始调用）
 
 @param workEngine 请求信息和回调
 */
- (void)downloadRequestWithDownloadWorkEngnine:(DDdownLoadnetWorkEngine *)workEngine;

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
- (void)deleteAllDownLoadCachedDatas;


@end
