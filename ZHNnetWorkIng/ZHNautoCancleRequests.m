//
//  ZHNautoCancleRequests.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "ZHNautoCancleRequests.h"
#import "ZHNbaseNetWork.h"

@interface ZHNautoCancleRequests()

@property (nonatomic,strong) NSMutableArray <NSNumber *> * requestArray;

@end


@implementation ZHNautoCancleRequests

- (void)dealloc{
    
    for (NSNumber * requestID in self.requestArray) {
        [[ZHNbaseNetWork shareInstance]cancleRequsetWithRequsetID:requestID];
    }
    [self removeAllRequestTasks];
}

- (void)cacheRequestTaskID:(NSNumber *)requestID{
    [self.requestArray addObject:requestID];
}

- (void)removeAllRequestTasks{
    [self.requestArray removeAllObjects];
}

#pragma mark - setter getter
- (NSMutableArray *)requestArray{
    if (_requestArray == nil) {
        _requestArray = [NSMutableArray array];
    }
    return _requestArray;
}

@end
