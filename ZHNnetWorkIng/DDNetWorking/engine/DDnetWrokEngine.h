//
//  ZHNnetWrokEngnine.h
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger,DDrequestType) {
    DDrequestTypeGET,
    DDrequestTypePOST
};

typedef NS_ENUM(NSInteger,DDrequestPriority) {
    DDrequestpriorityDefault,
    DDrequestpriorityLow,
    DDrequestPriorityHigh
};

typedef NS_ENUM(NSInteger,DDcacheType) {
    DDcacheTypeLocalCache,// 需要设置一个cachetime 有cache的情况下不去网络请求数据 (默认是这种策略，并且cachetime = -1)
    DDcacheTypeNetCache,// 有cache的情况先返回cache 然后再去网络请求数据
};

typedef NS_ENUM(NSInteger,DDresultType) {
    DDresultTypeNet,
    DDresultTypeCache
};

typedef void(^successBlock)(id result,DDcacheType cacheType,DDresultType resultType);
typedef void(^failureBlock)(NSError * error);

@class DDcacheMetaData;
@interface DDnetWrokEngine : NSObject

/**
 基础路径 (必填)
 */
@property (strong,nonatomic) NSString *baseURL;

/**
 请求的路径（必填,和request拼接成完整的路径）
 */
@property (nonatomic,copy) NSString * requestURL;

/**
 请求type (必填)
 */
@property (nonatomic,assign) DDrequestType requestType;

/**
 发起请求的控制器 (必填)（也可以是其他的对象）
 */
@property (nonatomic,weak) NSObject * control;

/**
 请求传递的参数
 */
@property (nonatomic,strong) NSDictionary * params;

/**
 成功的回调
 */
@property (nonatomic,copy) successBlock success;

/**
 失败的回调
 */
@property (nonatomic,copy) failureBlock failure;

/**
 缓存cache的策略 (可不填,默认是DDcacheTypeLocalCache且cacheTime为-1)
 */
@property (nonatomic,assign) DDcacheType cacheType;

/**
 需要缓存的时长 (可不填) (单位是秒,不填默认是-1，也就是不缓存  cacheTime需要和DDcacheTypeLocalCache配合使用，如果cacheTim和DDcacheTypeNetCache一起则cacheTime策略失效，以DDcacheTypeNetCache策略来做缓存)
 */
@property (nonatomic,assign) NSInteger cacheTime;

/**
 请求的优先级 (可不填，默认是default)
 */
@property (nonatomic,assign) DDrequestPriority requsetPriority;


/**
 初始化方法

 @param control 发起请求的对象
 @param baseUrl 请求的base url
 @param requestUrl 请求的路径
 @param requestType 请求的类型
 @param requestParams 请求的参数
 @param success 请求成功的回调
 @param failure 请求失败的回调
 */
+ (DDnetWrokEngine *)engineWithControl:(NSObject *)control
                               BaseUrl:(NSString *)baseUrl
                            requestUrl:(NSString *)requestUrl
                           requestType:(DDrequestType)requestType
                         requestParams:(NSDictionary *)requestParams
                               success:(successBlock)success
                               failure:(failureBlock)failure;
@end
