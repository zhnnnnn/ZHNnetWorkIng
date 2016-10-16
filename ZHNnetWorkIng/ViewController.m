//
//  ViewController.m
//  ZHNnetWorkIng
//
//  Created by zhn on 16/10/12.
//  Copyright © 2016年 zhn. All rights reserved.
//

#import "ViewController.h"
#import "ZHNbaseNetWrok+test.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
   [[ZHNbaseNetWrok shareInstance]zhn_getAllBarsWithControl:self Success:^(id result) {
        NSLog(@" === %@",result);
    } failure:^(NSError *error) {
        NSLog(@"%@",error);
    }];
//    [[ZHNbaseNetWrok shareInstance]cancleRequsetWithRequsetID:requsetID];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
