# KSYLiveSDK for iOS使用指南
---
##SDK说明
KSYLiveSDK for iOS(以下简称SDK)是基于RTMP的推流器

###运行环境
本SDK由SDK＋真机进行开发，demo也只能在真机上运行，主要利用CocoaTouch官方的AVAssertWriter系列方法进行音视频的硬编码，主要使用H264和AAC方式的编码

##集成使用引导

###SDK结构
- librtmp.a 推流的核心库，以静态库＋对应头文件的形式去引进
- KSYVideoPicker 采集视频的核心部分，主要的作用就是采集视频，转化为flv的数据，然后通过rtmp推流库，把视频流推到rtmp服务器上

###SDK使用方式
引入KSYPushVideoStream.a 和 相应的头文件即可，demo是一个最简单可以运行的示例

###集成
####初始化

- 创建一个KSYPushVideoStream实例

```
_pushVideoSteam = [[KSYPushVideoStream alloc] initWithDisplayVide:self.view andCaptureDevicePosition:AVCaptureDevicePositionBack];
```

- 开始推流

```
[_pushVideoStream setUrl:@"相应的rtmp的推流地址"];
[_pushVideoStream startRecord];
```

- 停止推流

```
[_pushVideoStream stopRecord];
```




