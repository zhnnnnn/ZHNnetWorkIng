//
//  NSObject+autoCancleAdd.h
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZHNautoCancleRequests.h"

@interface NSObject (autoCancleAdd)

@property (nonatomic,strong,readonly) ZHNautoCancleRequests * autoCancleRequests;

@end
