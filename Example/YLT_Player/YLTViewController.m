//
//  YLTViewController.m
//  YLT_Player
//
//  Created by xphaijj on 11/16/2017.
//  Copyright (c) 2017 xphaijj. All rights reserved.
//

#import "YLTViewController.h"
#import <YLT_Player/YLT_Player.h>

@interface YLTViewController ()

@end

@implementation YLTViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [YLT_VideoPlayer YLT_OpenFile:[[NSBundle mainBundle] pathForResource:@"kaoji" ofType:@"mp4"]];
//    [YLT_VideoPlayer YLT_OpenFile:[[NSBundle mainBundle] pathForResource:@"Test" ofType:@"mov"]];
    [YLT_VideoPlayer YLT_OpenFile:[[NSBundle mainBundle] pathForResource:@"video" ofType:@"mkv"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
