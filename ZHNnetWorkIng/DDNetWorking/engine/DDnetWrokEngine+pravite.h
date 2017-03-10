//
//  DDnetWrokEngnine+pravite.h
//  
//
//  Created by 张辉男 on 17/2/22.
//
//

#import "DDnetWrokEngine.h"

@interface DDnetWrokEngine ()
- (BOOL)isCacheTimeValide;
- (void)cachedResponseData:(NSData *)responseData metaData:(DDcacheMetaData *)metaData;
- (NSDictionary *)loadCacheData;
+ (void)clearAllcaches;
- (BOOL)clearCache;
@end
