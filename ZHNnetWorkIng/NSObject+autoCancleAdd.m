//
//  NSObject+autoCancleAdd.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "NSObject+autoCancleAdd.h"
#import <objc/runtime.h>

@implementation NSObject (autoCancleAdd)

#pragma mark - getter setter
- (ZHNautoCancleRequests *)autoCancleRequests{
    
   ZHNautoCancleRequests * requsets = objc_getAssociatedObject(self, @selector(autoCancleRequests));
    if (requsets == nil) {
        requsets = [[ZHNautoCancleRequests alloc]init];
        objc_setAssociatedObject(self, @selector(autoCancleRequests), requsets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return requsets;
}

@end
