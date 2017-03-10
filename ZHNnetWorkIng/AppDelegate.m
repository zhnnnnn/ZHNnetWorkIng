//
//  AppDelegate.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/12.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "AppDelegate.h"
#import "DDbaseNetWork.h"
#import "DDbaseNetWork+test.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

//    [DDNetWorkManager configBaseNetWorkNeedLogParams:NO errorCodeHandle:^(NSInteger errorCode) {
//        if (errorCode == 601) {
//           
//        }
//    }];
    
    [DDNetWorkManager configBaseNetWorkNeedLogParams:YES normalErrorHandle:nil authorErrorHandle:^(NSError *error, DDnetWrokEngine *engine) {
        if (error.code == -1011) {
            [DDNetWorkManager getSMScodeSuccess:^(id result, DDcacheType cacheType, DDresultType resultType) {
                NSLog(@"wtfffffffff");
                
            } failure:^(NSError *error) {
                
            }];
        }
    }];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
