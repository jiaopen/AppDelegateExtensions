//
//  ViewController.m
//  AppDelegateExtensionsDemo
//
//  Created by 苏合 on 2017/8/21.
//  Copyright © 2017年 Mobike. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegateExtensions.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle:) name:UIApplicationDidReceiveRemoteNotification object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handle:(NSNotification *)noti
{

}

@end
