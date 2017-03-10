//
//  testViewController.m
//  ZHNnetWorkIng
//
//  Created by 张辉男 on 17/2/24.
//  Copyright © 2017年 zhn. All rights reserved.
//

#import "testViewController.h"
#import "TestTableViewController.h"
#import "DDbaseNetWork.h"
#import "DDbaseNetWork+test.h"

@interface testViewController ()

@end

@implementation testViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    DDnetWrokEngine *engine = [[DDnetWrokEngine alloc]init];
//    engine.requestURL = @"http://139.196.197.21:8080/Hotcity/api/v1/bars";
//    engine.requestType = DDrequestTypeGET;
//    engine.params = nil;
//    [DDNetWorkManager deleteCacheWithWorkEngine:engine];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)pushToNextVC:(id)sender {
    TestTableViewController *testVC = [[TestTableViewController alloc]init];
    [self.navigationController pushViewController:testVC animated:true];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
