//
//  KSYAVAssetEncoder.m
//  IFVideoPickerControllerDemo
//
//  Created by Blues on 9/27/13.
//  Copyright (c) 2015 KSY. All rights reserved.
//

#import "KSYAVAssetEncoder.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVMediaFormat.h>
#import "KSYAudioEncoder.h"
#import "KSYVideoEncoder.h"
#import "NSData+Hex.h"
#import "KSYMP4Reader.h"
#import "KSYMP4Frame.h"
#import "KSYBytesData.h"
#import "NALUnit.h"
#import "KSYPendingSampleBuffer.h"

@interface KSYAVAssetEncoder () {
    KSYVideoEncoder *videoEncoder_;
    KSYAudioEncoder *audioEncoder_;
    // KSYMP4Reader *mp4Reader_;
    // NSMutableArray *timeStamps_;
    int firstPts_;
    // NALUnit *previousNalu;
    // NSMutableArray *pendingNalu_;
    BOOL readMovieMeta_;
    IFEncoderState encoderState_;
    NSMutableArray *pendingSampleBuffers_;
    NSMutableArray *newSampleBuffers_;
    
    dispatch_queue_t assetEncodingQueue_;
    dispatch_source_t dispatchSource_;
    
    BOOL watchOutputFileReady_;
    BOOL reInitializing_;
    BOOL readMetaHeader_;
    BOOL readMetaHeaderFinished_;
}

- (NSString *)getOutputFilePath:(NSString *)fileType;
- (id)initWithFileType:(NSString *)fileType;
- (NSString *)mediaPathForMediaType:(NSString *)mediaType;
- (BOOL)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer
                   ofType:(IFCapturedBufferType)mediaType;
- (BOOL)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer
             toWriterInput:(AVAssetWriterInput *)writerInput;
- (void)saveToAlbum:(NSURL *)url;
- (void)watchOutputFile:(NSString *)filePath;
- (BOOL)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer
                    ofType:(IFCapturedBufferType)mediaType
               assetWriter:(AVAssetWriter *)writer;
- (void)addMediaInput:(AVAssetWriterInput *)input
             toWriter:(AVAssetWriter *)writer;
- (double)getOldestPts;

@property (atomic, retain) NSString *fileType;

@end

@implementation KSYAVAssetEncoder

static const NSInteger kMaxTempFileLength = 1024 * 1024 * 5; // max file size
NSString *const kAVAssetMP4Output = @"ifavassetout.mp4";
NSString *const kAVAssetMP4OutputWithRandom = @"ifavassetout-%05d.mp4";//@"blues-sample.mp4";//
const char *kAssetEncodingQueue = "com.ifactorylab.ifassetencoder.encodingqueue";

@synthesize audioEncoder = audioEncoder_;
@synthesize videoEncoder = videoEncoder_;
@synthesize assetWriter;
@synthesize assetMetaWriter;
@synthesize outputURL;
@synthesize outputFileHandle;
@synthesize captureHandler;
@synthesize progressHandler;
@synthesize metaHeaderHandler;
@synthesize maxFileSize;
@synthesize fileType;
@synthesize encoderState = encoderState_;

+ (KSYAVAssetEncoder *)mpeg4BaseEncoder {
    return [[KSYAVAssetEncoder alloc] initWithFileType:AVFileTypeMPEG4];
}

+ (KSYAVAssetEncoder *)quickTimeMovieBaseEncoder {
    return [[KSYAVAssetEncoder alloc] initWithFileType:AVFileTypeQuickTimeMovie];
}

- (id)initWithFileType:(NSString *)aFileType {
    self = [super init];
    if (self != nil) {
        encoderState_ = kEncoderStateUnknown;
        watchOutputFileReady_ = NO;
        maxFileSize = 0;
        firstPts_ = -1;
        readMetaHeader_ = NO;
        readMetaHeaderFinished_ = NO;
        self.fileType = aFileType;
        reInitializing_ = NO;
        
        // ****
        pendingSampleBuffers_ = [[NSMutableArray alloc] initWithCapacity:10];
        newSampleBuffers_ = [[NSMutableArray alloc] initWithCapacity:10];
        readMovieMeta_ = NO;
        
        // Generate temporary file path to store encoded file
        self.outputURL = [NSURL fileURLWithPath:[self getOutputFilePath:fileType] isDirectory:NO];
        
        // Create serila queue for encoding given buffer
        assetEncodingQueue_ =
        dispatch_queue_create(kAssetEncodingQueue, DISPATCH_QUEUE_SERIAL);
        
        NSError *error = nil;
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:outputURL fileType:fileType error:&error];
        
        NSURL *metaFile = [NSURL fileURLWithPath:[self getOutputFilePath:fileType] isDirectory:NO];
        
        // We need to write one complete file to get 'moov' mp4 meta header
        self.assetMetaWriter = [[AVAssetWriter alloc] initWithURL:metaFile fileType:fileType error:&error];
        if (error) {
            NSLog(@"Failed to create assetWriter - %@, %@", [error localizedDescription], [error userInfo]);
        }
    }
    return self;
}

- (void)addMediaInput:(AVAssetWriterInput *)input
             toWriter:(AVAssetWriter *)writer {
    if (writer && input && [writer canAddInput:input]) {
        @try {
            [writer addInput:input];
        } @catch (NSException *exception) {
            NSLog(@"Couldn't add input: %@", [exception description]);
        }
    }
}

- (void)setVideoEncoder:(KSYVideoEncoder *)videoEncoder {
    [self addMediaInput:videoEncoder.assetWriterInput toWriter:assetMetaWriter];
    [self addMediaInput:videoEncoder.assetWriterInput toWriter:assetWriter];
    videoEncoder_ = videoEncoder;
}

- (void)setAudioEncoder:(KSYAudioEncoder *)audioEncoder {
    [self addMediaInput:audioEncoder.assetWriterInput toWriter:assetMetaWriter];
    [self addMediaInput:audioEncoder.assetWriterInput toWriter:assetWriter];
    audioEncoder_ = audioEncoder;
}

- (NSString *)getOutputFilePath:(NSString *)fileType {
    NSString *path = NSTemporaryDirectory();
    NSString *filePath =  [path stringByAppendingPathComponent:
                           [NSString stringWithFormat:kAVAssetMP4OutputWithRandom, rand() % 99999]];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    
    NSLog(@"************************************************");
    NSLog(@"*********** create new mp4 file ****************");
    NSLog(@"************************************************");
    
    return filePath;
}

- (NSString *)mediaPathForMediaType:(NSString *)mediaType {
    NSArray *paths =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                        NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *suffix = mediaType;
    return [basePath stringByAppendingPathComponent:suffix];
}

- (BOOL)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer
             toWriterInput:(AVAssetWriterInput *)writerInput {
    if (writerInput.readyForMoreMediaData) {
        @try {
            if (![writerInput appendSampleBuffer:sampleBuffer]) {
                NSLog(@"Failed to append sample buffer: %@", [assetWriter error]);
                return NO;
            }
            return YES;
        } @catch (NSException *exception) {
            NSLog(@"Couldn't append sample buffer: %@", [exception description]);
            return NO;
        }
    }
    return NO;
}

- (BOOL)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer
                    ofType:(IFCapturedBufferType)mediaType
               assetWriter:(AVAssetWriter *)writer {
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"here??");
        return NO;
    }
    
    if (writer.status == AVAssetWriterStatusUnknown) {
        if ([writer startWriting]) {
            @try {
                CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                [writer startSessionAtSourceTime:startTime];
            }
            @catch (NSException *exception) {
                NSLog(@"Couldn't add audio input: %@", [exception description]);
                return NO;
            }
        } else {
            NSLog(@"Failed to start writing(%@): %@", writer.outputURL,
                  [writer error]);
            return NO;
        }
    }
    NSLog(@"write.status = %@",@(writer.status));
    if (writer.status == AVAssetWriterStatusWriting) {
        AVAssetWriterInput *input = nil;
        if (mediaType == kBufferVideo) {
            input = videoEncoder_.assetWriterInput;
        } else if (mediaType == kBufferAudio) {
            input = audioEncoder_.assetWriterInput;
        }
        
        if (input != nil) {
            return [self appendSampleBuffer:sampleBuffer toWriterInput:input];
        }
    }
    
    return NO;
}

- (void)start {
    self.encoderState = kEncoderStateRunning;
}

- (void)setEncoderState:(IFEncoderState)encoderState {
    @synchronized (self) {
        encoderState_ = encoderState;
    }
}

- (IFEncoderState)getEncoderState {
    @synchronized (self) {
        return encoderState_;
    }
}

- (void)handleMetaData {
    NSData *movWithMoov = [NSData dataWithContentsOfFile:assetMetaWriter.outputURL.path];
    if ([movWithMoov length] > 0) {
        // Let's parse mp4 header
        KSYMP4Reader *mp4Reader = [[KSYMP4Reader alloc] init];
        [mp4Reader readData:[KSYBytesData dataWithNSData:movWithMoov]];
    }
    assetMetaWriter = nil;
    
    @synchronized (self) {
        readMetaHeaderFinished_ = YES;
    }
}

- (BOOL)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(IFCapturedBufferType)mediaType {
    // Even if stream is coming, just do nothing if we are not ready yet.
    if (self.encoderState != kEncoderStateRunning) {
        return NO;
    }
    
    @synchronized (self) {
        if (!readMetaHeader_) {
            // If we don't finish writing in AVAssetWriter, we never get 'moov' section
            // for parsing mp4 file.
            
            if ([self encodeSampleBuffer:sampleBuffer ofType:mediaType assetWriter:assetMetaWriter]) {
                // We finish encoding here for meta data
                readMetaHeader_ = YES;
                [assetMetaWriter finishWritingWithCompletionHandler:^{
                    [self handleMetaData];
                }];
            }
        }
    }
    
    @synchronized (self) {
        if (!readMetaHeaderFinished_) {
            // If the meta header hasn't parsed yet, we don't start encoding.
            return YES;
        }
    }
    
    if ([self encodeSampleBuffer:sampleBuffer ofType:mediaType assetWriter:assetWriter]) {
        if (!watchOutputFileReady_) {
            [self watchOutputFile:[outputURL path]];
        }
    }
    else {
        NSLog(@"*************** Failed to encode given sample buffer");
        return NO;
    }
    return YES;
}

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(IFCapturedBufferType)mediaType {
    if (assetEncodingQueue_) {
        CFRetain(sampleBuffer);
        // We'd like encoding job running asynchronously
        dispatch_async(assetEncodingQueue_, ^{
            // NSLog(@"*************** MEDIA STREAM COMING");
//            [pendingSampleBuffers_ addObject:
//             [KSYPendingSampleBuffer pendingSampleBuffer:sampleBuffer ofType:mediaType]];
//            NSLog(@"pendingSampleBuffers_.count = %@",@(pendingSampleBuffers_.count));

            
            int writtenBufferCount = 0;
            if (pendingSampleBuffers_.count > 0) {
                for (KSYPendingSampleBuffer *pending in pendingSampleBuffers_) {
                    CMSampleBufferRef buf = [pending getSampleBuffer];
                    if (![self writeSampleBuffer:buf ofType:pending.mediaType]) {
                        break;
                    }
                    writtenBufferCount++;
                }
                
                for (int i = 0; i < writtenBufferCount; ++i) {
                    [pendingSampleBuffers_ removeObjectAtIndex:0];
                }
            }
            
            
            
            
            // Write the given sample buffer to output file through AVAssetWriter
            if (pendingSampleBuffers_.count > 0 || ![self writeSampleBuffer:sampleBuffer ofType:mediaType]) {
                
//                if (pendingSampleBuffers_.count > 70) {
//                    [newSampleBuffers_ addObject:
//                     [KSYPendingSampleBuffer pendingSampleBuffer:sampleBuffer ofType:mediaType]];
//                    NSLog(@"newSampleBuffers_.count = %@",@(newSampleBuffers_.count));
//                    return ;
//                }
//                if (pendingSampleBuffers_.count < 75) {
                    [pendingSampleBuffers_ addObject:
                     [KSYPendingSampleBuffer pendingSampleBuffer:sampleBuffer ofType:mediaType]];
                    NSLog(@"pendingSampleBuffers_.count = %@",@(pendingSampleBuffers_.count));

//                }
//            else {
//                    NSLog(@"超出范围！");
//                }
            
            }
            
            CFRelease(sampleBuffer);
        });
    }
    else {
        NSLog(@"No valid assetEncodingQueue_ exist");
    }
}

- (void)saveToAlbum:(NSURL *)url {
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    if ([assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:url]) {
        [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:url
                                          completionBlock:^(NSURL *assetURL, NSError *error) {
                                          }];
    }
}

- (void)stop {
    if (self.encoderState == kEncoderStateFinishing) {
        self.encoderState = kEncoderStateStopped;
    }
    else {
        // Stop detecting file growth.
        if (dispatchSource_) {
            dispatch_source_cancel(dispatchSource_);
            dispatchSource_ = NULL;
        }
        
        if (assetWriter.status == AVAssetWriterStatusWriting) {
            @try {
                if (self.encoderState == kEncoderStateStopped) {
                    self.encoderState = kEncoderStateFinishing;
                    
                    @synchronized (self) {
                        [self.audioEncoder.assetWriterInput markAsFinished];
                        [self.videoEncoder.assetWriterInput markAsFinished];
                    }
                    
                    [assetWriter finishWritingWithCompletionHandler:^{
                        self.encoderState = kEncoderStateFinished;
                        if (assetWriter.status == AVAssetWriterStatusFailed) {
                            NSLog(@"Failed to finish writing: %@", [assetWriter error]);
                        } else {
                            
                        }
                    }];
                }
            } @catch (NSException *exception) {
                NSLog(@"Caught exception: %@", [exception description]);
            }
        }
        else {
            
        }
    }
    
    if (assetEncodingQueue_ != nil) {
        assetEncodingQueue_ = nil;
    }
}

- (double)getOldestPts {
    double pts = 0;
    return pts;
}

- (void)watchOutputFile:(NSString *)filePath {
    dispatch_queue_t queue =
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // int file = open([filePath UTF8String], O_EVTONLY);
    double movieBitrate = self.videoEncoder.bitRate + self.audioEncoder.bitRate;
    self.outputFileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    dispatchSource_ = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                             [outputFileHandle fileDescriptor],
                                             DISPATCH_VNODE_DELETE |
                                             DISPATCH_VNODE_WRITE |
                                             DISPATCH_VNODE_EXTEND |
                                             DISPATCH_VNODE_ATTRIB |
                                             DISPATCH_VNODE_LINK |
                                             DISPATCH_VNODE_RENAME |
                                             DISPATCH_VNODE_REVOKE,
                                             queue);
    dispatch_source_set_event_handler(dispatchSource_, ^{
        // Read data flags from the created source
        unsigned long flags = dispatch_source_get_data(dispatchSource_);
        // If the file has deleted, cancel current watching job.
        if (flags & DISPATCH_VNODE_DELETE) {
            dispatch_source_cancel(dispatchSource_);
            dispatchSource_ = nil;
        }
        
        // When file size has changed,
        if (flags & DISPATCH_VNODE_EXTEND) {
            // unsigned long long currentOffset = [outputFileHandle offsetInFile];
            NSData *chunk = [outputFileHandle readDataToEndOfFile];
            
            // Let's make each chunk contains at least half second movie.
            if ([chunk length] > (movieBitrate / 10)) {
//            if ([chunk length] > (movieBitrate * 20)) {
                if (assetWriter.status == AVAssetWriterStatusWriting) {
                    if (self.encoderState != kEncoderStateRunning) {
                        // If the current status is not running, don't do anything here
                        return;
                    }
                    
                    @try {
                        // Update current encoder status to "EncoderFinishing"
                        self.encoderState = kEncoderStateFinishing;
                        
                        // Regardless of job failure, we need to reset current encoder
                        dispatch_source_cancel(dispatchSource_);
                        dispatchSource_ = nil;
                        [videoEncoder_.assetWriterInput markAsFinished];
                        [audioEncoder_.assetWriterInput markAsFinished];
                        NSLog(@"assetWrite will Finish!");
                        
                        // Wait until it finishes
                        [assetWriter finishWritingWithCompletionHandler:^{
                            
                            
                            @synchronized (self)
                            {
                                NSLog(@"assetWriter finishWriting");
                                // Meanwhile finishing, if we received stop signal, don't restart
                                // asset encoder again.
                                BOOL restartEncoder = YES;
                                if (self.encoderState == kEncoderStateStopped) {
                                    restartEncoder = NO;
                                }
                                
                                if (assetWriter.status == AVAssetWriterStatusFailed) {
                                    NSLog(@"Failed to finish writing: %@", [assetWriter error]);
                                } else {
                                    NSData *movWithMoov =
                                    [NSData dataWithContentsOfFile:assetWriter.outputURL.path];
                                    
                                    NSArray *frames = nil;
                                    KSYMP4Reader *mp4Reader = [[KSYMP4Reader alloc] init];
                                    
                                    if ([movWithMoov length] > 0) {
                                        // Let's parse mp4 header
                                        [mp4Reader readData:[KSYBytesData dataWithNSData:movWithMoov]];
                                        frames = [mp4Reader readFrames];
                                        if (!readMovieMeta_ && metaHeaderHandler) {
                                            readMovieMeta_ = YES;
                                            metaHeaderHandler(mp4Reader);
                                        }
                                    }
                                    
                                    if (captureHandler) {
                                        captureHandler(frames, movWithMoov);
                                    }
                                    assetMetaWriter = nil;
                                    assetWriter = nil;
                                }
                                
                                if (restartEncoder) {
                                    // Once it's done, generate new file name and reinitiate AVAssetWrite
                                    self.outputURL = [NSURL fileURLWithPath:[self getOutputFilePath:fileType]
                                                                isDirectory:NO];
                                    NSError *error;
                                    assetWriter = [[AVAssetWriter alloc] initWithURL:outputURL
                                                                            fileType:fileType
                                                                               error:&error];
                                    
                                    // setVideoEncoder and setAudioEncoder will retain the given
                                    // encoder objects so we need to reduce reference as it's retained
                                    // in the functions.
                                    [assetWriter addInput:videoEncoder_.assetWriterInput];
                                    [assetWriter addInput:audioEncoder_.assetWriterInput];
                                    
                                    self.encoderState = kEncoderStateRunning;
                                    NSLog(@"重新开始新一轮的写入");
                                    // we are good to go.
                                    @synchronized (self) {
                                        watchOutputFileReady_ = NO;
                                    }
                                } else {
                                    // Update current encoder status to "EncoderFinished", if we
                                    // don't start the encoder again.
                                    self.encoderState = kEncoderStateFinished;
                                }

                            }

                            
                        }];
                    } @catch (NSException *exception) {
                        NSLog(@"Caught exception: %@", [exception description]);
                        self.encoderState = kEncoderStateFinished;
                    }
                }
            } else {
                [outputFileHandle seekToFileOffset:0];
            }
        }
    });
    
    dispatch_source_set_cancel_handler(dispatchSource_, ^(void){
        [outputFileHandle closeFile];
    });
    
    dispatch_resume(dispatchSource_);
    watchOutputFileReady_ = YES;
}

- (void)dealloc {
    
}

@end
