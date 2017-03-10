//
//  ZHNbaseNetWrok.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/12.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "DDbaseNetWork.h"
#import "AFNetworking.h"
#import "NSObject+autoCancleAdd.h"
#import "DDcacheMetaData.h"
#import "NSString+HASH.h"
#import "DDnetWrokEngine+pravite.h"

#define WEAKSELF  __weak typeof(self) weakSelf = self
#define STRONGSELF __strong typeof(self) strongSelf = weakSelf

#ifdef DEBUG
#define ZHNAppLog(s, ... ) NSLog( @"[%@ in line %d] ==================================================>%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define ZHNAppLog(s, ... )
#endif

@interface DDbaseNetWork()<NSURLSessionDataDelegate>

/**
 普通的mamanger
 */
@property (nonatomic,strong) AFHTTPSessionManager * sessionManager;

/**
 存普通task的字典（为了cancle效果）
 */
@property (nonatomic,strong) NSMutableDictionary * sessionDataTaskDictionary;

/**
 存放下载的task的字典
 */
@property (nonatomic,strong) NSMutableDictionary * sessionDownLoadTaskDictionary;

/**
 每个下载任务对应一个engine
 */
@property (nonatomic,strong) NSMutableDictionary * workEngineDictionary;

/**
 锁
 */
@property (nonatomic,strong) NSRecursiveLock * lock;

/**
 网络请求成功和失败的时候是否需要打印一些信息
 */
@property (nonatomic,getter = isNeedLog) BOOL needLog;

/**
 对于errorCode的封装操作
 */
@property (nonatomic,copy) DDErrorHandleBlock errorCodeHandle;

/**
 判断接口是否需要授权操作
 */
@property (nonatomic,getter = isRequsetNeedAuthor) BOOL requestNeedAuthor;

/**
 授权错误的处理
 */
@property (nonatomic,copy) DDauthorErrorHandleBlock authorErrorHandle;

/**
 队列
 */
@property (strong,nonatomic) dispatch_queue_t networkQueue;

@end


@implementation DDbaseNetWork


#pragma mark public method
+ (instancetype)shareInstance{

    static DDbaseNetWork * baseNetWork;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        baseNetWork = [[DDbaseNetWork alloc]init];
        baseNetWork.networkQueue = dispatch_queue_create("DDbaseNetWorkQueue", DISPATCH_QUEUE_CONCURRENT);
    });
    return baseNetWork;
}

- (NSNumber *)callRequestWithWorkEngnine:(DDnetWrokEngine *)workEngine{
    
    DDcacheMetaData * metaData = [[DDcacheMetaData alloc]init];
    metaData.createDate = [NSDate date];
    WEAKSELF;
    // 请求的类型
    NSString * requestMethod;
    switch (workEngine.requestType) {
        case DDrequestTypeGET:
            requestMethod = @"GET";
            break;
        case DDrequestTypePOST:
            requestMethod = @"POST";
        default:
            break;
    }
    // 生成请求
    if (workEngine.baseURL == nil) {
        workEngine.baseURL = @"";
    }
    NSString *fullRequsetUrlSrring = [NSString stringWithFormat:@"%@%@",workEngine.baseURL,workEngine.requestURL];
    NSURLSessionDataTask * task = [self p_dataTaskWithHTTPMethod:requestMethod URLString:fullRequsetUrlSrring parameters:workEngine.params uploadProgress:nil downloadProgress:nil success:^(NSURLSessionDataTask * task, id responseObject) {
        STRONGSELF;
        
        // 请求取消了的话
        if (task.state == NSURLSessionTaskStateCanceling) {return;}
        
        // 删除为了自动取消请求缓存的请求id
        [workEngine.control.autoCancleRequests cacheRequestTaskID:[NSNumber numberWithInteger:task.hash]];
        
        // 移除缓存的task
        [self.lock lock];
        [strongSelf p_removeRetuestWithDataTask:task];
        [self.lock unlock];
        
        // 成功的情况
        if (responseObject) {
            if (self.isNeedLog) {
                ZHNAppLog(@"\n");
                ZHNAppLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",
                          [self p_generateGETAbsoluteURL:workEngine.requestURL params:workEngine.params],
                          workEngine.params,
                          [self p_tryToParseData:responseObject]);
            }
            
            if (workEngine.cacheTime > 0 || workEngine.cacheType == DDcacheTypeNetCache) {// 缓存一波
                NSData * dictData;
                if ([responseObject isKindOfClass:[NSData class]]) {
                    dictData = responseObject;
                }else {
                    dictData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
                }
                [workEngine cachedResponseData:dictData metaData:metaData];
            }
            
            NSAssert(workEngine.cacheTime >= -1, @"网络请求的cacheTime需要大于0");
            
            if (workEngine.success) {
                if([responseObject isKindOfClass:[NSData class]]) {
                    responseObject = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
                }
                workEngine.success(responseObject,workEngine.cacheType,DDresultTypeNet);
            }
        }

    } failure:^(NSURLSessionDataTask * task, NSError * error) {
        // 失败的回调
        if (error) {
            
            // 需要授权操作的处理
            if (self.authorErrorHandle) {
                self.authorErrorHandle(error,workEngine);
            }
            
            // 失败的回调
            if(self.errorCodeHandle) {
                self.errorCodeHandle(error);
            }
            // 错误的回调
            if (workEngine.failure) {
                workEngine.failure(error);
            }
            // 是否需要打印
            if (self.isNeedLog) {
                ZHNAppLog(@"\n");
                NSString *format = @" params: ";
                if ([error code] == NSURLErrorCancelled) {
                    ZHNAppLog(@"\nRequest was canceled mannully, URL: %@ %@%@\n\n",
                              [self p_generateGETAbsoluteURL:workEngine.requestURL params:workEngine.params],
                              format,
                              workEngine.params);
                }else{
                    ZHNAppLog(@"\nRequest error, URL: %@ %@%@\n errorInfos:%@\n\n",
                              [self p_generateGETAbsoluteURL:workEngine.requestURL params:workEngine.params],
                              format,
                              workEngine.params,
                              [error localizedDescription]);
                }
            }
        }
    }];
    
    // 请求优先级
    float priority = NSURLSessionTaskPriorityDefault;
    switch (workEngine.requsetPriority) {
        case DDrequestpriorityDefault:
            priority = NSURLSessionTaskPriorityDefault;
            break;
        case DDrequestpriorityLow:
            priority = NSURLSessionTaskPriorityLow;
        case DDrequestPriorityHigh:
            priority = NSURLSessionTaskPriorityHigh;
    }
    task.priority = priority;
    
    // dealloc的时候自动处理请求的取消
    NSNumber *requestID = [NSNumber numberWithUnsignedInteger:task.hash];
    [workEngine.control.autoCancleRequests cacheRequestTaskID:requestID];
    
    // 缓存datatask为了cancle效果
    [self p_addRetuestWithDataTask:task];

    // 缓存策略的处理
    dispatch_async(self.networkQueue, ^{
        if (workEngine.cacheType == DDcacheTypeLocalCache) {// locacache
            BOOL cached =  [workEngine isCacheTimeValide];
            if (cached) {
                NSDictionary *dict = [workEngine loadCacheData];
                if (dict) {
                    [self p_callResultSuccess:workEngine dict:dict];
                    [self cancleRequsetWithRequsetID:[NSNumber numberWithUnsignedInteger:task.hash]];
                }else {
                    [task resume];
                }
            }else {
                [task resume];
            }
        }else if (workEngine.cacheType == DDcacheTypeNetCache) {// netcache
            NSDictionary *dict = [workEngine loadCacheData];
            if (dict) {
                [self p_callResultSuccess:workEngine dict:dict];
            }
            [task resume];
        }
    });
    
    return requestID;
}


- (void)cancleRequsetWithRequsetID:(NSNumber *)requestID{

    NSURLSessionDataTask * task = [self.sessionDataTaskDictionary objectForKey:requestID];
    [task cancel];
    
    [self.lock lock];
    [self.sessionDataTaskDictionary removeObjectForKey:requestID];
    [self.lock unlock];
}

- (void)configBaseNetWorkNeedLogParams:(BOOL)needLog errorHandle:(DDErrorHandleBlock)errorHandle{
    _needLog = needLog;
    _errorCodeHandle = errorHandle;
}

- (void)configBaseNetWorkNeedLogParams:(BOOL)needLog normalErrorHandle:(DDErrorHandleBlock)normalErrorHandle authorErrorHandle:(DDauthorErrorHandleBlock)authorErrorHandle {
    _needLog = needLog;
    _errorCodeHandle = normalErrorHandle;
    _authorErrorHandle = authorErrorHandle;
    if (_authorErrorHandle != nil) {
        _requestNeedAuthor = YES;
    }else {
        _requestNeedAuthor = NO;
    }
}


- (void)deleteCacheWithWorkEngine:(DDnetWrokEngine *)engine {
    [engine clearCache];
}

- (void)deleteAllNormalRequestCaches {
    [DDnetWrokEngine clearAllcaches];
}


- (void)downloadRequestWithDownloadWorkEngnine:(DDdownLoadnetWorkEngine *)workEngine{
    
    // 下载完成了
    if (workEngine.isDownLoaded) {
        workEngine.progress(workEngine.cachedDataSize,workEngine.cachedDataSize,1.0);
        workEngine.downLoadState(ZHNdownLoadStateCompleted);
        workEngine.complete(ZHNFileFullpath(workEngine.fullDownLoadUrl));
        
        return;
    }
    
    // 在下载就暂停 暂停的就开始下载
    NSURLSessionDataTask * cacheedTask = self.sessionDownLoadTaskDictionary[ZHNFileName(workEngine.fullDownLoadUrl)];
    if (cacheedTask) {
        if (cacheedTask.state == NSURLSessionTaskStateRunning) {
            workEngine.downLoadState(ZHNdownLoadStatePause);
            [cacheedTask suspend];
        }else{
            workEngine.downLoadState(ZHNdownLoadStateStart);
            [cacheedTask resume];
        }
        return;
    }
    
    // 创建缓存的文件夹
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:ZHNCachesDirectory]) {
        [fileManager createDirectoryAtPath:ZHNCachesDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    // 创建流
    NSURLSession * downLoadSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
    NSOutputStream * outPutStrem = [NSOutputStream outputStreamToFileAtPath:ZHNFileFullpath(workEngine.fullDownLoadUrl) append:YES];
    workEngine.outPutStrem = outPutStrem;
    
    // 创建请求
    NSMutableURLRequest * requset = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:workEngine.fullDownLoadUrl]];
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", ZHNDownloadLength(workEngine.fullDownLoadUrl)];
    [requset setValue:range forHTTPHeaderField:@"Range"];
    
    // 拿到请求任务
    NSURLSessionDataTask * task = [downLoadSession dataTaskWithRequest:requset];
   
    // 缓存任务和engnine
    [self.sessionDownLoadTaskDictionary setObject:task forKey:ZHNFileName(workEngine.fullDownLoadUrl)];
    NSNumber * workengineKey = [NSNumber numberWithInteger:task.hash];
    [self.workEngineDictionary setObject:workEngine forKey:workengineKey];
    
    // 开始下载
    [task resume];
    workEngine.downLoadState(ZHNdownLoadStateStart);
}

- (NSInteger)fileTotalLength:(NSString *)urlString{
    return [[NSDictionary dictionaryWithContentsOfFile:ZHNTotalLengthFullpath][ZHNFileName(urlString)] integerValue];
}

- (NSInteger)downLoadedFileLength:(NSString *)urlString{
    return ZHNDownloadLength(ZHNFileName(urlString));
}

- (BOOL)isCompleteDownLoaded:(NSString *)urlString{
    if ([self fileTotalLength:urlString] == [self isCompleteDownLoaded:urlString]) {
        return YES;
    }else{
        return NO;
    }
}

- (void)deleteCachedDataWithUrlString:(NSString *)uslString{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:ZHNFileFullpath(uslString)]) {
        
        // 删除沙盒中的资源
        [fileManager removeItemAtPath:ZHNFileFullpath(uslString) error:nil];
        // 删除任务
        NSURLSessionDataTask * downLoadTask = self.sessionDownLoadTaskDictionary[ZHNFileName(uslString)];
        DDdownLoadnetWorkEngine * workEngine = self.workEngineDictionary[[NSNumber numberWithInteger:downLoadTask.hash]];
        [workEngine.outPutStrem close];
        [downLoadTask cancel];
        [self.workEngineDictionary removeObjectForKey:[NSNumber numberWithInteger:downLoadTask.hash]];
        [self.sessionDownLoadTaskDictionary removeObjectForKey:ZHNFileName(uslString)];

        // 删除资源总长度
        if ([fileManager fileExistsAtPath:ZHNTotalLengthFullpath]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:ZHNTotalLengthFullpath];
            [dict removeObjectForKey:ZHNFileName(uslString)];
            [dict writeToFile:ZHNTotalLengthFullpath atomically:YES];
        }
    }
}

- (void)deleteAllDownLoadCachedDatas{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:ZHNCachesDirectory]) {
        // 删除沙盒中所有资源
        [fileManager removeItemAtPath:ZHNCachesDirectory error:nil];
        // 删除任务
        for (DDdownLoadnetWorkEngine *downLoadEngine in [self.workEngineDictionary allValues]) {
            [downLoadEngine.outPutStrem close];
        }
        [self.workEngineDictionary removeAllObjects];
        [[self.sessionDownLoadTaskDictionary allValues] makeObjectsPerformSelector:@selector(cancel)];
        [self.sessionDownLoadTaskDictionary removeAllObjects];
        
        // 删除资源总长度
        if ([fileManager fileExistsAtPath:ZHNTotalLengthFullpath]) {
            [fileManager removeItemAtPath:ZHNTotalLengthFullpath error:nil];
        }
    }
}

#pragma mark - urlsessiondatadelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    NSNumber * workEngineKey = [NSNumber numberWithInteger:dataTask.hash];
    DDdownLoadnetWorkEngine * downLoadWorkEngnine = self.workEngineDictionary[workEngineKey];
    
    // 存储最大长度
    NSMutableDictionary * totalLengthDict = [NSMutableDictionary dictionaryWithContentsOfFile:ZHNTotalLengthFullpath];
    if (totalLengthDict == nil) {
        totalLengthDict = [NSMutableDictionary dictionary];
    }
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + ZHNDownloadLength(downLoadWorkEngnine.fullDownLoadUrl);
    [totalLengthDict setObject:@(totalLength) forKey:ZHNFileName(downLoadWorkEngnine.fullDownLoadUrl)];
    [totalLengthDict writeToFile:ZHNTotalLengthFullpath atomically:YES];
    downLoadWorkEngnine.dataTotalLength = totalLength;
    
    // 打开流
    [downLoadWorkEngnine.outPutStrem open];
    
    // 接收这个请求
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data{
    
    NSNumber * workEngineKey = [NSNumber numberWithInteger:dataTask.hash];
    DDdownLoadnetWorkEngine * downLoadWorkEngnine = self.workEngineDictionary[workEngineKey];
    
    // 写入数据
    [downLoadWorkEngnine.outPutStrem write:data.bytes maxLength:data.length];
    
    // 下载进度
    NSUInteger totalLength = downLoadWorkEngnine.dataTotalLength;
    NSUInteger recivedLength = ZHNDownloadLength(downLoadWorkEngnine.fullDownLoadUrl);
    CGFloat progress = (CGFloat)recivedLength/(CGFloat)totalLength;
    downLoadWorkEngnine.progress(recivedLength,totalLength,progress);
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    
    NSNumber * workEngineKey = [NSNumber numberWithInteger:task.hash];
    DDdownLoadnetWorkEngine * downLoadWorkEngnine = self.workEngineDictionary[workEngineKey];
    if (!downLoadWorkEngnine) {return;}
    
    if (ZHNDownloadLength(downLoadWorkEngnine.fullDownLoadUrl) == downLoadWorkEngnine.dataTotalLength) {
        // 下载完成了
        downLoadWorkEngnine.downLoadState(ZHNdownLoadStateCompleted);
        downLoadWorkEngnine.complete(ZHNFileFullpath(downLoadWorkEngnine.fullDownLoadUrl));
    }else if(error){
        // 下载失败了
        downLoadWorkEngnine.failure(error);
        downLoadWorkEngnine.downLoadState(ZHNdownLoadStateFailued);
    }
    
    // 清空状态
    [downLoadWorkEngnine.outPutStrem close];
    downLoadWorkEngnine.outPutStrem = nil;
    [self.sessionDownLoadTaskDictionary removeObjectForKey:ZHNFileName(downLoadWorkEngnine.fullDownLoadUrl)];
    [self.workEngineDictionary removeObjectForKey:workEngineKey];
}

//#pragma mark tatget method
//- (void)applictionWillBeKilled{
//    [DDnetWrokEngine clearAllcaches];
//}

#pragma mark - pravite method
- (void)p_callResultSuccess:(DDnetWrokEngine *)workEngine dict:(NSDictionary *)dict {
    if (workEngine.success) {
        workEngine.success(dict,workEngine.cacheType,DDresultTypeCache);
    }
    if (self.isNeedLog) {
        ZHNAppLog(@"\n");
        ZHNAppLog(@"缓存的数据");
        ZHNAppLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",
                  [self p_generateGETAbsoluteURL:workEngine.requestURL params:workEngine.params],
                  workEngine.params,dict);
    }
}

- (void)p_removeRetuestWithDataTask:(NSURLSessionDataTask *)dataTask{
    [self.lock lock];
    NSNumber *requestID = [NSNumber numberWithUnsignedInteger:dataTask.hash];
    [self.sessionDataTaskDictionary removeObjectForKey:requestID];
    [self.lock unlock];
}

- (void)p_addRetuestWithDataTask:(NSURLSessionDataTask *)dataTask{
    [self.lock lock];
    NSNumber *requestID = [NSNumber numberWithUnsignedInteger:dataTask.hash];
    [self.sessionDataTaskDictionary setObject:dataTask forKey:requestID];
    [self.lock unlock];
}

- (NSString *)p_generateGETAbsoluteURL:(NSString *)url params:(id)params {
    if (params == nil || ![params isKindOfClass:[NSDictionary class]] || [params count] == 0) {
        return url;
    }
    
    NSString *queries = @"";
    for (NSString *key in params) {
        id value = [params objectForKey:key];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            continue;
        } else if ([value isKindOfClass:[NSArray class]]) {
            continue;
        } else if ([value isKindOfClass:[NSSet class]]) {
            continue;
        } else {
            queries = [NSString stringWithFormat:@"%@%@=%@&",
                       (queries.length == 0 ? @"&" : queries),
                       key,
                       value];
        }
    }
    
    if (queries.length > 1) {
        queries = [queries substringToIndex:queries.length - 1];
    }
    
    if (([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) && queries.length > 1) {
        if ([url rangeOfString:@"?"].location != NSNotFound
            || [url rangeOfString:@"#"].location != NSNotFound) {
            url = [NSString stringWithFormat:@"%@%@", url, queries];
        } else {
            queries = [queries substringFromIndex:1];
            url = [NSString stringWithFormat:@"%@?%@", url, queries];
        }
    }
    
    return url.length == 0 ? queries : url;
}

- (id)p_tryToParseData:(id)responseData {
    if ([responseData isKindOfClass:[NSData class]]) {
        // 尝试解析成JSON
        if (responseData == nil) {
            return responseData;
        } else {
            NSError *error = nil;
            NSDictionary * response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            if (error != nil) {
                return responseData;
            } else {
                return response;
            }
        }
    } else {
        return responseData;
    }
}

- (NSURLSessionDataTask *)p_dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                  uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgress
                                downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:URLString relativeToURL:self.sessionManager.baseURL] absoluteString] parameters:parameters error:&serializationError];
    if (serializationError) {
        if (failure) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_async(self.sessionManager.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        
        return nil;
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self.sessionManager dataTaskWithRequest:request
                          uploadProgress:uploadProgress
                        downloadProgress:downloadProgress
                       completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                           if (error) {
                               if (failure) {
                                   failure(dataTask, error);
                               }
                           } else {
                               if (success) {
                                   success(dataTask, responseObject);
                               }
                           }
                       }];
    
    return dataTask;
}

#pragma mark - getter setter
- (AFHTTPSessionManager *)sessionManager{
    if (_sessionManager == nil) {
        AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/html", @"application/json", @"text/json", @"text/javascript", nil];
        manager.securityPolicy.allowInvalidCertificates= YES;
        manager.securityPolicy.validatesDomainName = NO;
        manager.operationQueue.maxConcurrentOperationCount = 5;
        manager.requestSerializer.timeoutInterval = 30;
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _sessionManager = manager;
    }
    return _sessionManager;
}


- (NSMutableDictionary *)sessionDataTaskDictionary{
    if (_sessionDataTaskDictionary == nil) {
        _sessionDataTaskDictionary = [NSMutableDictionary dictionary];
    }
    return _sessionDataTaskDictionary;
}

- (NSMutableDictionary *)sessionDownLoadTaskDictionary{
    if (_sessionDownLoadTaskDictionary == nil) {
        _sessionDownLoadTaskDictionary = [NSMutableDictionary dictionary];
    }
    return _sessionDownLoadTaskDictionary;
}

- (NSMutableDictionary *)workEngineDictionary{
    if (_workEngineDictionary == nil) {
        _workEngineDictionary = [NSMutableDictionary dictionary];
    }
    return _workEngineDictionary;
}

- (NSRecursiveLock *)lock{
    if (_lock == nil) {
        _lock = [[NSRecursiveLock alloc]init];
    }
    return _lock;
}

@end
