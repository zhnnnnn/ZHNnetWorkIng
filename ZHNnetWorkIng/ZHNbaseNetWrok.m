//
//  ZHNbaseNetWrok.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/12.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "ZHNbaseNetWrok.h"
#import "AFNetworking.h"
#import "NSObject+autoCancleAdd.h"
#import "ZHNcacheMetaData.h"

#define WEAKSELF  __weak typeof(self) weakSelf = self
#define STRONGSELF __strong typeof(self) strongSelf = weakSelf

#ifdef DEBUG
#define ZHNAppLog(s, ... ) NSLog( @"[%@ in line %d] ==================================================>%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define ZHNAppLog(s, ... )
#endif

@interface ZHNbaseNetWrok()

@property (nonatomic,strong) AFHTTPSessionManager * sessionManager;

/**
 存放task的数组（为了cancle效果）
 */
@property (nonatomic,strong) NSMutableDictionary * sessionDataTaskDictionary;

// 锁
@property (nonatomic,strong) NSLock * lock;

// 网络请求成功和失败的时候是否需要打印一些信息
@property (nonatomic,getter = isNeedLog) BOOL needLog;
@end


@implementation ZHNbaseNetWrok


#pragma mark public method

- (instancetype)init{
    
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applictionWillBeKilled) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

+ (instancetype)shareInstance{

    static ZHNbaseNetWrok * baseNetWork;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        baseNetWork = [[ZHNbaseNetWrok alloc]init];
    });
    return baseNetWork;
}

- (NSNumber *)callRequestWithWorkEngnine:(ZHNnetWrokEngnine *)workEngine{
    
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

- (NSLock *)lock{
    if (_lock) {
        _lock = [[NSLock alloc]init];
    }
    return _lock;
}

@end
