//
//  ZHNnetWorkIngTests.m
//  ZHNnetWorkIngTests
//
//  Created by zhn on 16/10/12.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DDbaseNetWork.h"
#import "DDnetWrokEngine+pravite.h"

#define testUrl2 @"http://139.196.197.21:8080/Hotcity/api/v1/bars"
#define testUrl @"http://139.196.197.21:8080/Hotcity/api/v1/gifts"


typedef  void(^testBlock)(DDresultType type);
@interface ZHNnetWorkIngTests : XCTestCase

@end

@implementation ZHNnetWorkIngTests

- (void)setUp {
    [super setUp];
    [self clearCacheURL:testUrl];
    [self clearCacheURL:testUrl2];
}

- (void)tearDown {
    [super tearDown];
    [self clearCacheURL:testUrl];
    [self clearCacheURL:testUrl2];
}

- (void)testNetCache {
    [self clearCacheURL:testUrl];
    [self p_netCacheCallTestRequest];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
}

- (void)testLocalCache {
    [self clearCacheURL:testUrl2];
    [self p_localCacheCallTestRequest];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}


#pragma mark - 
#pragma mark --
- (void)clearCacheURL:(NSString *)url {
    DDnetWrokEngine *engine = [[DDnetWrokEngine alloc]init];
    engine.requestURL = url;
    engine.params = nil;
    engine.requestType = DDrequestTypeGET;
    [DDNetWorkManager deleteCacheWithWorkEngine:engine];
}

- (void)p_netCacheCallTestRequest {
    XCTestExpectation *expectation = [self expectationWithDescription:@"netCache异步网络加载"];
    __block BOOL firstTime = YES;
    DDnetWrokEngine *engine = [DDnetWrokEngine engineWithControl:self BaseUrl:testUrl requestUrl:@"" requestType:DDrequestTypeGET requestParams:nil success:^(id result, DDcacheType cacheType, DDresultType resultType) {
        if (firstTime) {
            XCTAssertEqual(resultType, DDresultTypeCache);
            firstTime = NO;
        }else {
            XCTAssertEqual(resultType, DDresultTypeNet);
            [expectation fulfill];
        }
    } failure:^(NSError *error) {
        XCTFail(@"");
    }];
    engine.cacheType = DDcacheTypeNetCache;
    [DDNetWorkManager callRequestWithWorkEngnine:engine];
}

- (void)p_localCacheCallTestRequest{
    XCTestExpectation *expectation = [self expectationWithDescription:@"localCache异步网络加载"];
    [self p_praviteCallRequest:^(DDresultType type) {
        XCTAssertEqual(type, DDresultTypeNet);
        [self p_praviteCallRequest:^(DDresultType type) {
            XCTAssertEqual(type, DDresultTypeCache);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_praviteCallRequest:^(DDresultType type) {
                    XCTAssertEqual(type, DDresultTypeNet);
                } isend:YES expectation:expectation];
            });
        } isend:NO expectation:expectation];
    } isend:NO expectation:expectation];
}

- (void)p_praviteCallRequest:(testBlock)testAction isend:(BOOL)end expectation:(XCTestExpectation *)expectation{
    DDnetWrokEngine *engine = [DDnetWrokEngine engineWithControl:self BaseUrl:testUrl2 requestUrl:@"" requestType:DDrequestTypeGET requestParams:nil success:^(id result, DDcacheType cacheType, DDresultType resultType) {
        testAction(resultType);
        if (end) {
            [expectation fulfill];
        }
    } failure:^(NSError *error) {
    }];
    engine.cacheTime = 10;
    [DDNetWorkManager callRequestWithWorkEngnine:engine];
}

@end
