//
//  ZHNbaseNetWrok.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/12.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "ZHNbaseNetWork.h"
#import "AFNetworking.h"
#import "NSObject+autoCancleAdd.h"
#import "ZHNcacheMetaData.h"
#import "NSString+HASH.h"

#define WEAKSELF  __weak typeof(self) weakSelf = self
#define STRONGSELF __strong typeof(self) strongSelf = weakSelf

#ifdef DEBUG
#define ZHNAppLog(s, ... ) NSLog( @"[%@ in line %d] ==================================================>%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define ZHNAppLog(s, ... )
#endif

@interface ZHNbaseNetWork()<NSURLSessionDataDelegate>

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

// 锁
@property (nonatomic,strong) NSLock * lock;

// 网络请求成功和失败的时候是否需要打印一些信息
@property (nonatomic,getter = isNeedLog) BOOL needLog;
@end


@implementation ZHNbaseNetWork


#pragma mark public method

- (instancetype)init{
    
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applictionWillBeKilled) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

+ (instancetype)shareInstance{

    static ZHNbaseNetWork * baseNetWork;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        baseNetWork = [[ZHNbaseNetWork alloc]init];
    });
    return baseNetWork;
}

- (NSNumber *)callRequestWithWorkEngnine:(ZHNnetWrokEngnine *)workEngine{
    
    // 获取本地数据
    ZHNcacheMetaData * metaData = [[ZHNcacheMetaData alloc]init];
    metaData.createDate = [NSDate date];
    BOOL cached =  [workEngine isCacheTimeValide];
    if (cached) {
        NSDictionary * dict =  [workEngine loadCacheData];
        if (dict) {
            if (workEngine.success) {
                workEngine.success(dict);
            }
            if (self.isNeedLog) {
                ZHNAppLog(@"\n");
                ZHNAppLog(@"\nRequest success, URL: %@\n params:%@\n response:缓存的数据\n\n",
                          [self p_generateGETAbsoluteURL:workEngine.requestURL params:workEngine.params],
                          workEngine.params);
            }
            return nil;
        }
    }
    
    WEAKSELF;
    // 请求的类型
    NSString * requestMethod;
    switch (workEngine.requestType) {
        case ZHNrequestTypeGET:
            requestMethod = @"GET";
            break;
        case ZHNrequestTypePOST:
            requestMethod = @"POST";
        default:
            break;
    }
    // 生成请求
    NSError * serializerError;
    NSURLRequest * request = [self.sessionManager.requestSerializer requestWithMethod:requestMethod URLString:workEngine.requestURL parameters:workEngine.params error:&serializerError];
    NSURLSessionDataTask * task =  [self.sessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        STRONGSELF;
        // 移除缓存的task
        [strongSelf p_removeRetuestWithDataTask:task];
        // 成功的情况
        if (responseObject) {
            if (workEngine.success) {
                workEngine.success(responseObject);
            }
            if (self.isNeedLog) {
                ZHNAppLog(@"\n");
                ZHNAppLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",
                          [self p_generateGETAbsoluteURL:workEngine.requestURL params:workEngine.params],
                          workEngine.params,
                          [self p_tryToParseData:response]);
            }
            
            if (workEngine.cacheTime > 0) {// 缓存一波
                NSData * dictData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
                [workEngine cachedResponseData:dictData metaData:metaData];
            }
        }
        // 失败的回调
        if (error) {
            if (workEngine.failure) {
                workEngine.failure(error);
            }
            
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
    
    // dealloc的时候自动处理请求的取消
    NSNumber *requestID = [NSNumber numberWithUnsignedInteger:task.hash];
    [workEngine.control.autoCancleRequests cacheRequestTaskID:requestID];
    
    // 缓存datatask为了cancle效果
    [self p_addRetuestWithDataTask:task];
    [task resume];
    
    return requestID;
}



- (void)cancleRequsetWithRequsetID:(NSNumber *)requestID{

    NSURLSessionDataTask * task = [self.sessionDataTaskDictionary objectForKey:requestID];
    [task cancel];
    
    [self.lock lock];
    [self.sessionDataTaskDictionary removeObjectForKey:requestID];
    [self.lock unlock];
}

- (void)configBaseNetWorkWithBaseUrl:(NSString *)baseURL needLogParams:(BOOL)needLog{
    _baseURL = baseURL;
    _needLog = needLog;
}


- (void)downloadRequestWithDownloadWorkEngnine:(ZHNdownLoadnetWorkEngnine *)workEngine{
    
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
        ZHNdownLoadnetWorkEngnine * workEngine = self.workEngineDictionary[[NSNumber numberWithInteger:downLoadTask.hash]];
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

- (void)deleteAllCachedDatas{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:ZHNCachesDirectory]) {
        // 删除沙盒中所有资源
        [fileManager removeItemAtPath:ZHNCachesDirectory error:nil];
        // 删除任务
        for (ZHNdownLoadnetWorkEngnine *downLoadEngine in [self.workEngineDictionary allValues]) {
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
    ZHNdownLoadnetWorkEngnine * downLoadWorkEngnine = self.workEngineDictionary[workEngineKey];
    
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
    ZHNdownLoadnetWorkEngnine * downLoadWorkEngnine = self.workEngineDictionary[workEngineKey];
    
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
    ZHNdownLoadnetWorkEngnine * downLoadWorkEngnine = self.workEngineDictionary[workEngineKey];
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

#pragma mark tatget method
- (void)applictionWillBeKilled{
    [ZHNnetWrokEngnine clearAllcaches];
}

#pragma mark - pravite method
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

#pragma mark - getter setter
- (AFURLSessionManager *)sessionManager{
    if (_sessionManager == nil) {
        AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/html", @"application/json", @"text/json", @"text/javascript", nil];
        manager.securityPolicy.allowInvalidCertificates= YES;
        manager.securityPolicy.validatesDomainName = NO;
        manager.requestSerializer.timeoutInterval = 10.0f;
        manager.operationQueue.maxConcurrentOperationCount = 3;
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

- (NSLock *)lock{
    if (_lock) {
        _lock = [[NSLock alloc]init];
    }
    return _lock;
}

@end
