//
//  ZHNbaseNetWrok+test.h
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/16.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "ZHNbaseNetWrok.h"

@interface ZHNbaseNetWrok (test)

- (NSNumber *)zhn_getAllBarsWithControl:(NSObject *)control
                                Success:(successBlock)success
                                failure:(errorBlock)failure;

- (void)zhn_downLoadUrl:(NSString *)dataUrl
               progress:(progressBlcok)progress
               complete:(downLoadCompleteBlock)complete
                failure:(downLoadErrorBlock)failure
          downLoadState:(downLoadStatesBlock)downLoadState;

@end
