//
//  ZHNdownLoadnetWorkEngnine.h
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/19.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 缓存主目录
#define ZHNCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"ZHNCache"]

// 保存文件名
#define ZHNFileName(url) url.md5String

// 文件的存放路径（caches）
#define ZHNFileFullpath(url) [ZHNCachesDirectory stringByAppendingPathComponent:ZHNFileName(url)]

// 文件的已下载长度
#define ZHNDownloadLength(url) [[[NSFileManager defaultManager] attributesOfItemAtPath:ZHNFileFullpath(url) error:nil][NSFileSize] integerValue]


#define ZHNTotalLengthFullpath [ZHNCachesDirectory stringByAppendingPathComponent:@"totalLength.plist"]

typedef NS_ENUM(NSInteger,ZHNdownLoadState) {
    ZHNdownLoadStateStart,
    ZHNdownLoadStatePause,
    ZHNdownLoadStateCompleted,
    ZHNdownLoadStateFailued
};

typedef void(^progressBlcok) (NSInteger receivedSize, NSInteger expectedSize, CGFloat progress);
typedef void(^downLoadCompleteBlock) (NSString * cachedPath);
typedef void(^downLoadErrorBlock) (NSError * error);
typedef void(^downLoadStatesBlock) (ZHNdownLoadState downLoadState);

@interface DDdownLoadnetWorkEngine : NSObject

//========================需要赋值的属性============================//
@property (nonatomic,copy) NSString * fullDownLoadUrl;

@property (nonatomic,copy) progressBlcok progress;

@property (nonatomic,copy) downLoadErrorBlock failure;

@property (nonatomic,copy) downLoadCompleteBlock complete;

@property (nonatomic,copy) downLoadStatesBlock downLoadState;

//======================私有属性===============================//
@property (nonatomic,getter = isDownLoaded,readonly) BOOL downloaded;
@property (nonatomic,copy,readonly) NSString * currentCachedPath;
@property (nonatomic,assign,readonly) NSInteger cachedDataSize;
@property (nonatomic,assign) NSInteger dataTotalLength;
@property (nonatomic,strong) NSOutputStream * outPutStrem;

@end
