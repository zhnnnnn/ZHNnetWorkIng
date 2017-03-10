//
//  TestTableViewController.m
//  ZHNnetWorkIng
//
//  Created by 张辉男 on 17/2/23.
//  Copyright © 2017年 zhn. All rights reserved.
//

#import "TestTableViewController.h"
#import "DDbaseNetWork+test.h"
#import "YYModel.h"
#import "testModel.h"
#import "testCell.h"

@interface TestTableViewController ()
@property (nonatomic,copy) NSArray *resultArray;
@end

@implementation TestTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[testCell class] forCellReuseIdentifier:@"key"];
 
    
    [DDNetWorkManager zhn_getAllBarsWithControl:self Success:^(id result, DDcacheType cacheType, DDresultType resultType) {
        
        if (resultType == DDresultTypeCache) {
            NSLog(@"缓存的数据");
        }else {
            NSLog(@"网络的数据");
        }
//        self.resultArray = [NSArray yy_modelArrayWithClass:[testModel class] json:result[@"data"]];
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.tableView reloadData];
        });
    } failure:^(NSError *error) {
        
    }];
    
    NSLog(@"显示在最前面表示方法是异步的");
    
//    [DDNetWorkManager cancleRequsetWithRequsetID:requestID];
    
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)dealloc {
    NSLog(@"控制器dealloc");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.resultArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    testCell *cell = [tableView dequeueReusableCellWithIdentifier:@"key" forIndexPath:indexPath];
    testModel *model = self.resultArray[indexPath.row];
    cell.model = model;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 150;
}

@end
