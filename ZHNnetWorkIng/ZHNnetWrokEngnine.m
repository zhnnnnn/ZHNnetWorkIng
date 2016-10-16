//
//  ZHNnetWrokEngnine.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "ZHNnetWrokEngnine.h"
#import "NSString+netWorkAdd.h"
#import "ZHNcacheMetaData.h"

@implementation ZHNnetWrokEngnine


- (instancetype)init{
    if (self = [super init]) {
        self.cacheTime = -1;
    }
    return self;
}

- (void)cachedResponseData:(NSData *)responseData metaData:(ZHNcacheMetaData *)metaData{
    if (self.cacheTime > 0) {
        [responseData writeToFile:[self cacheFilePath] atomically:YES];
        [NSKeyedArchiver archiveRootObject:metaData toFile:[self cacheMetadataFilePath]];
    }
}

- (BOOL)isCacheTimeValide{
    ZHNcacheMetaData * metaData = [self loadCacheMetadata];
    NSDate *creationDate = metaData.createDate;
    NSTimeInterval duration = -[creationDate timeIntervalSinceNow];
    if (duration < 0 || duration > self.cacheTime) {
        return NO;
    }else{
        return YES;
    }
}


- (ZHNcacheMetaData *)loadCacheMetadata {
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

+ (void)clearAllcaches{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
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
    NSString *cacheFileName = [NSString md5StringFromString:requestInfo];
    return cacheFileName;
}

- (NSString *)cacheMetadataFilePath {
    NSString *cacheMetadataFileName = [NSString stringWithFormat:@"%@.metadata", [self cacheFileName]];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheMetadataFileName];
    return path;
}

- (NSString *)cacheBasePath {
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
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
