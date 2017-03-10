//
//  ZHNautoCancleRequests.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "DDautoCancleRequests.h"
#import "DDbaseNetWork.h"

@interface DDautoCancleRequests()

@property (nonatomic,strong) NSMutableArray <NSNumber *> * requestArray;

@end


@implementation DDautoCancleRequests

- (void)dealloc{
    
    for (NSNumber * requestID in self.requestArray) {
        [[DDbaseNetWork shareInstance]cancleRequsetWithRequsetID:requestID];
    }
    [self removeAllRequestTasks];
}

- (void)cacheRequestTaskID:(NSNumber *)requestID{
    if (![self.requestArray containsObject:requestID]) {
        [self.requestArray addObject:requestID];
    }
}

- (void)removeAllRequestTasks{
    [self.requestArray removeAllObjects];
}

- (void)removeRequestTaskWithID:(NSNumber *)requestID {
    [self.requestArray removeObject:requestID];
}

#pragma mark - setter getter
- (NSMutableArray *)requestArray{
    if (_requestArray == nil) {
        _requestArray = [NSMutableArray array];
    }
    return _requestArray;
}

@end
