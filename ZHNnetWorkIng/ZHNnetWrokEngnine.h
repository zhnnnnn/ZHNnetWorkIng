//
//  ZHNnetWrokEngnine.h
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^successBlock)(id result);
typedef void(^errorBlock)(NSError * error);

typedef NS_ENUM(NSInteger,ZHNrequestType) {
    ZHNrequestTypeGET,
    ZHNrequestTypePOST
};
@class ZHNcacheMetaData;
@interface ZHNnetWrokEngnine : NSObject

/**
 请求的路径（必填）
 */
@property (nonatomic,copy) NSString * requestURL;

/**
 请求发type (必填)
 */
@property (nonatomic,assign) ZHNrequestType requestType;

/**
 发起请求的控制器 (必填)（也可以是其他的对象）
 */
@property (nonatomic,strong) NSObject * control;

/**
 请求传递的参数 (必填)
 */
@property (nonatomic,strong) NSDictionary * params;

/**
 成功的回调 (必填)
 */
@property (nonatomic,copy) successBlock success;

/**
 失败的回调 (必填)
 */
@property (nonatomic,copy) errorBlock failure;

/**
 需要缓存的时长 (可不填) (单位是秒,不填默认是-1，也就是不缓存)
 */
@property (nonatomic,assign) NSInteger cacheTime;


// ============= 内部方法外部禁止调用 ==================//
- (BOOL)isCacheTimeValide;
- (void)cachedResponseData:(NSData *)responseData metaData:(ZHNcacheMetaData *)metaData;
- (NSDictionary *)loadCacheData;
+ (void)clearAllcaches;
@end
