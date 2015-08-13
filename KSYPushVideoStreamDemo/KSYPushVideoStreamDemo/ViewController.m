//
//  ViewController.m
//  KSYPushVideoStreamDemo
//
//  Created by Blues on 15/7/9.
//  Copyright (c) 2015年 Blues. All rights reserved.
//

#import "ViewController.h"
#import "KSYPushVideoStream.h"

@interface ViewController () {
    IBOutlet UIButton *_recordButton;
    KSYPushVideoStream *_pushVideoStream;
    UILabel *_label;
    NSString *_string;
    NSTimer *_timer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _label = [[UILabel alloc] initWithFrame:CGRectMake(20, 50, 150, 30)];
    _label.textColor = [UIColor whiteColor];
    _label.backgroundColor = [UIColor clearColor];
    _label.text = @"0 M/S";
    [self.view addSubview:_label];


    // **** 初始化
    _pushVideoStream = [[KSYPushVideoStream initialize] initWithDisplayView:self.view andCaptureDevicePosition:AVCaptureDevicePositionBack];
    

    _pushVideoStream.pushVideoStreamBlock = ^(double speed){
        if (speed > 0) {
            _string = [NSString stringWithFormat:@"%.0f M/S",speed];

        }else {
            _string = @"0 M/S";
        }
    };
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(changeSpeed) userInfo:nil repeats:YES];
    
    NSLog(@"%@",timer);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification:)name:UIApplicationDidBecomeActiveNotification object:nil];


}

- (void)changeSpeed{
    if (_string.length > 0) {
        _label.text = _string;

    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (IBAction)clickRecordBtn:(id)sender {
    
    if ([_pushVideoStream isCapturing] == NO) {

        [_pushVideoStream setUrl:@"rtmp://192.168.135.185/myLive/asdf111"];

        [_pushVideoStream startRecord];
        [_recordButton setTitle:@"停止录制" forState:UIControlStateNormal];
    }
    else {
        [_pushVideoStream stopRecord];
        [_recordButton setTitle:@"开始录制" forState:UIControlStateNormal];
    }
}

-(void)applicationWillResignActive:(NSNotification *)notification
{

    [_pushVideoStream stopRecord];
    NSLog(@"后台挂起");
}

-(void)applicationDidBecomeActiveNotification:(NSNotification *)notification
{
    [_pushVideoStream startRecord];
    NSLog(@"切换前台");
}
@end
