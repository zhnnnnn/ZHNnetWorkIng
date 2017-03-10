//
//  ZHNnetWrokEngnine.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "DDnetWrokEngine.h"
#import "DDcacheMetaData.h"
#import "NSString+HASH.h"
#import "DDnetWrokEngine+pravite.h"

@implementation DDnetWrokEngine


- (instancetype)init{
    if (self = [super init]) {
        self.cacheTime = -1;
    }
    return self;
}

+ (DDnetWrokEngine *)engineWithControl:(NSObject *)control BaseUrl:(NSString *)baseUrl requestUrl:(NSString *)requestUrl requestType:(DDrequestType)requestType requestParams:(NSDictionary *)requestParams success:(successBlock)success failure:(failureBlock)failure {
    DDnetWrokEngine *engine = [[DDnetWrokEngine alloc]init];
    engine.baseURL = baseUrl;
    engine.requestURL = requestUrl;
    engine.control = control;
    engine.requestType = requestType;
    engine.params = requestParams;
    engine.success = success;
    engine.failure = failure;
    return engine;
}


- (void)cachedResponseData:(NSData *)responseData metaData:(DDcacheMetaData *)metaData{
    [responseData writeToFile:[self cacheFilePath] atomically:YES];
    [NSKeyedArchiver archiveRootObject:metaData toFile:[self cacheMetadataFilePath]];
}

- (BOOL)isCacheTimeValide{
    DDcacheMetaData * metaData = [self loadCacheMetadata];
    NSDate *creationDate = metaData.createDate;
    NSTimeInterval duration = -[creationDate timeIntervalSinceNow];
    if (duration < 0 || duration > self.cacheTime) {
        return NO;
    }else{
        return YES;
    }
}


- (DDcacheMetaData *)loadCacheMetadata {
    NSString *path = [self cacheMetadataFilePath];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }
    return nil;
}

- (NSDictionary *)loadCacheData {
    NSString *path = [self cacheFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        return dict;
    }
    return nil;
}

- (BOOL)clearCache {
    NSString *path = [self cacheFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL success = [fileManager removeItemAtPath:path error:&error];
    return  success;
}

+ (void)clearAllcaches{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfLibrary stringByAppendingPathComponent:@"LazyRequestCache"];
    [fileManager removeItemAtPath:path error:nil];
}

#pragma mark - 路径的创建
- (NSString *)cacheFilePath {
    NSString *cacheFileName = [self cacheFileName];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheFileName];
    return path;
}

- (NSString *)cacheFileName {
    NSString *requestInfo = [NSString stringWithFormat:@"Method:%ldUrl:%@Argument:%@",
                             (long)self.requestType, self.requestURL, self.params];
    NSString *cacheFileName = requestInfo.md5String;
    return cacheFileName;
}

- (NSString *)cacheMetadataFilePath {
    NSString *cacheMetadataFileName = [NSString stringWithFormat:@"%@.metadata", [self cacheFileName]];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheMetadataFileName];
    return path;
}

- (NSString *)cacheBasePath {
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfLibrary stringByAppendingPathComponent:@"LazyRequestCache"];
    [self createDirectoryIfNeeded:path];
    return path;
}

- (void)createDirectoryIfNeeded:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES
                                                   attributes:nil error:&error];
    }
}

@end
