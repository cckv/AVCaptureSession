//
//  ViewController.m
//  AVCaptureSession
//
//  Created by bairuitech on 2019/4/22.
//  Copyright © 2019年 bairuitech. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureFileOutputRecordingDelegate>
{
    // 会话
    AVCaptureSession          *_session;
    
    // 输入
    AVCaptureDeviceInput      *_deviceInput;
    
    // 输出
    AVCaptureConnection       *_videoConnection;
    AVCaptureConnection       *_audioConnection;
    
    AVCaptureVideoDataOutput  *_videoOutput;
    AVCaptureStillImageOutput *_imageOutput;
    
    AVCaptureMovieFileOutput  *FileOutput;
    
    BOOL                       _isCamenaBack;
    AVCaptureVideoPreviewLayer * previewLayer;
    NSString                   *videoPath;
    NSInteger                 tapCount;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    videoPath = [self createVideoFilePath];
    tapCount = 0;
    
    NSError *error = [self setUpSession];
    
    if (!error) {
        
        previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        UIView * aView = self.view;
        previewLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [aView.layer addSublayer:previewLayer];
        
        [self startCaptureSession];
        
    }
    
}

- (NSError*)setUpSession
{
    NSError *error;
    _session = [[AVCaptureSession alloc]init];
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    
    [self setupSessionInputs:&error];
    
    [self setupSessionOutputs:&error];
    
    [self setUpFileOut];
    
    return error;
}

/// 输入
- (void)setupSessionInputs:(NSError **)error{
    // 视频输入
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:error];
    if (videoInput) {
        if ([_session canAddInput:videoInput]){
            [_session addInput:videoInput];
        }
    }
    _deviceInput = videoInput;
    
    // 音频输入
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioIn = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:error];
    if ([_session canAddInput:audioIn]){
        [_session addInput:audioIn];
    }
}

/// 输出
- (void)setupSessionOutputs:(NSError **)error{
    dispatch_queue_t captureQueue = dispatch_queue_create("com.cc.captureQueue", DISPATCH_QUEUE_SERIAL);
    
    // 视频输出
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    [videoOut setAlwaysDiscardsLateVideoFrames:YES];
    [videoOut setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
    [videoOut setSampleBufferDelegate:self queue:captureQueue];
    if ([_session canAddOutput:videoOut]){
        [_session addOutput:videoOut];
    }
    _videoOutput = videoOut;
    _videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    
    // 音频输出
    AVCaptureAudioDataOutput *audioOut = [[AVCaptureAudioDataOutput alloc] init];
    [audioOut setSampleBufferDelegate:self queue:captureQueue];
    if ([_session canAddOutput:audioOut]){
        [_session addOutput:audioOut];
    }
    _audioConnection = [audioOut connectionWithMediaType:AVMediaTypeAudio];
    
    // 静态图片输出
    AVCaptureStillImageOutput *imageOutput = [[AVCaptureStillImageOutput alloc] init];
    if (@available(iOS 11.0, *)) {
        imageOutput.outputSettings = @{AVVideoCodecKey:AVVideoCodecTypeJPEG};
    } else {
        imageOutput.outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    }
    if ([_session canAddOutput:imageOutput]) {
        [_session addOutput:imageOutput];
    }
    _imageOutput = imageOutput;
}

- (void)setUpFileOut
{
    // 3.1初始化设备输出对象，用于获得输出数据
    FileOutput=[[AVCaptureMovieFileOutput alloc]init];
    
    // 3.2设置输出对象的一些属性
    AVCaptureConnection *captureConnection=[FileOutput connectionWithMediaType:AVMediaTypeVideo];
    //设置防抖
    //视频防抖 是在 iOS 6 和 iPhone 4S 发布时引入的功能。到了 iPhone 6，增加了更强劲和流畅的防抖模式，被称为影院级的视频防抖动。相关的 API 也有所改动 (目前为止并没有在文档中反映出来，不过可以查看头文件）。防抖并不是在捕获设备上配置的，而是在 AVCaptureConnection 上设置。由于不是所有的设备格式都支持全部的防抖模式，所以在实际应用中应事先确认具体的防抖模式是否支持：
    if ([captureConnection isVideoStabilizationSupported ]) {
        captureConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
    }
    //预览图层和视频方向保持一致
    captureConnection.videoOrientation = [previewLayer connection].videoOrientation;
    
    // 3.3将设备输出添加到会话中
    if ([_session canAddOutput:FileOutput]) {
        [_session addOutput:FileOutput];
    }
}

#pragma mark - -会话控制
// 开启捕捉
- (void)startCaptureSession{
    if (!_session.isRunning){
        [_session startRunning];
    }
}

// 停止捕捉
- (void)stopCaptureSession{
    if (_session.isRunning){
        [_session stopRunning];
    }
}

#pragma mark - delegate
-(void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    NSLog(@"%@",sampleBuffer);
}

-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    NSLog(@"%@",sampleBuffer);
    
    @autoreleasepool {
        
        //视频
//        if (connection == [_videoConnection connectionWithMediaType:AVMediaTypeVideo]) {
//
//
//        }
//
//        //音频
//        if (connection == [_audioConnection connectionWithMediaType:AVMediaTypeAudio]) {
//
//        }
    }
    
}

#pragma mark - touch
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{

    if (tapCount  == 5) {
        [FileOutput stopRecording];
    }
    
    if ((tapCount % 5 ) == 1) {
        [self writeDataTofile];// 写入视频
    }

    tapCount += 1;
    
//    [self shiftCamera];// 切换摄像头
    
}

- (void)writeDataTofile
{
    NSURL *videoUrl = [NSURL fileURLWithPath:videoPath];
    [FileOutput startRecordingToOutputFileURL:videoUrl recordingDelegate:self];
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"Save video fail:%@",error);
        } else {
            NSLog(@"Save video succeed.");
        }
    }];
}

-(void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections{}

- (void)getVidioImage
{
    AVCaptureConnection *connection = [_imageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [_imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        if (error) {
            return;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [[UIImage alloc]initWithData:imageData];
        NSLog(@"%@",image);
    }];
}

//切换前后相机
-(void)shiftCamera
{
    _isCamenaBack = !_isCamenaBack;
    
    //切换至前置摄像头
    if(_isCamenaBack){
        
        AVCaptureDevice *device=nil;
        NSArray *devices=[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for(AVCaptureDevice *tmp in devices)
        {
            if(tmp.position==AVCaptureDevicePositionFront)
                device=tmp;
        }
        [_session beginConfiguration];
        [_session removeInput:_deviceInput];
        _deviceInput=nil;
        _deviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:device error:nil];
        if([_session canAddInput:_deviceInput])
            [_session addInput:_deviceInput];
        [_session commitConfiguration];
        
    }else{//切换至后置摄像头
        
        AVCaptureDevice *device=nil;
        NSArray *devices=[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for(AVCaptureDevice *tmp in devices)
        {
            if(tmp.position==AVCaptureDevicePositionBack)
                device=tmp;
        }
        [_session beginConfiguration];
        [_session removeInput:_deviceInput];
        _deviceInput=nil;
        _deviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:device error:nil];
        if([_session canAddInput:_deviceInput])
            [_session addInput:_deviceInput];
        [_session commitConfiguration];
    }
}


//写入的视频路径
- (NSString *)createVideoFilePath
{
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString];
    NSString *path = [[self videoFolder] stringByAppendingPathComponent:videoName];
    return path;
}

//存放视频的文件夹
- (NSString *)videoFolder
{
    NSString *cacheDir = [self cachesDir];
    NSString *direc = [cacheDir stringByAppendingPathComponent:@"vidioDir"];
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:direc]) {
        NSError *error = [NSError new];
        [[NSFileManager defaultManager] createDirectoryAtPath:direc withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return direc;
}

- (NSString *)cachesDir {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
}

@end
