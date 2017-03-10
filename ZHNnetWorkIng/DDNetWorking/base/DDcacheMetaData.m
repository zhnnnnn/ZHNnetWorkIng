//
//  ZHNcacheMetaData.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "DDcacheMetaData.h"

@implementation DDcacheMetaData

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        self.createDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:NSStringFromSelector(@selector(createDate))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.createDate forKey:NSStringFromSelector(@selector(createDate))];
}


@end
