//
//  ZHNdownLoadnetWorkEngnine.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/19.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "DDdownLoadnetWorkEngine.h"
#import "NSString+HASH.h"

@implementation DDdownLoadnetWorkEngine

- (void)setFullDownLoadUrl:(NSString *)fullDownLoadUrl{
    _fullDownLoadUrl = fullDownLoadUrl;
    
    // 如果下载的内容大小和需要下载的内容大小一样
    if ([self fileCurrentUrlTotalLength:fullDownLoadUrl] && ZHNDownloadLength(fullDownLoadUrl)==[self fileCurrentUrlTotalLength:fullDownLoadUrl]) {
        _downloaded = YES;
        _currentCachedPath = ZHNFileFullpath(fullDownLoadUrl);
        _cachedDataSize = [self fileCurrentUrlTotalLength:fullDownLoadUrl];
    }
}

- (NSInteger)fileCurrentUrlTotalLength:(NSString *)url
{
   return [[NSDictionary dictionaryWithContentsOfFile:ZHNTotalLengthFullpath][ZHNFileName(url)]integerValue];
}


@end
