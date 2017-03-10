//
//  ZHNautoCancleRequests.h
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDautoCancleRequests : NSObject

- (void)cacheRequestTaskID:(NSNumber *)requestID;

- (void)removeAllRequestTasks;

- (void)removeRequestTaskWithID:(NSNumber *)requestID;

@end
