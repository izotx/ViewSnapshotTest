//
//  CaptureManager.m
//  ViewSnapshotTest
//
//  Created by sadmin on 1/11/14.
//  Copyright (c) 2014 DJMobileInc. All rights reserved.
//

#import "CaptureManager.h"
#import "LinearInterpView.h"
#import "DrawingOperation.h"
#import "ScreenCaptureView.h"
#import "DJVideoWriter.h"

@interface CaptureManager()
    @property (nonatomic,strong) NSTimer * timer; // capture timer
    @property __block int frameRate; // default frame rate
    @property (nonatomic,strong) NSOperationQueue * queue;
    @property  int frameCount;
    @property (nonatomic,strong) DJVideoWriter * writer;
@property BOOL markedToStop;

@end
@implementation CaptureManager

-(instancetype)init{
    if(self= [super init]){
        self.frameRate =15.0;
        _queue = [[NSOperationQueue alloc]init];
        [_queue setMaxConcurrentOperationCount:1];
        _frameCount =0;
        [self.queue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    }
    return  self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([keyPath isEqualToString:@"operationCount"]){
      //  NSLog(@"Operation Count %@", change);
        if([[change objectForKey:@"new"] isEqual:@0]){
            if(self.markedToStop){
                NSLog(@"Completed");                
                [_writer stopRecording];
            }
        }
    }
}

-(void)startCapturing{
    //set up timer
    assert(self.paintView||self.captureView||self.backgroundView||self.entireView);
    //prepare writer with completion block
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *fileArray = [fileManager URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask];
    NSString *filePath = [NSString stringWithFormat:@"%@cache%d.mov", fileArray.lastObject, arc4random()%1000 ];
    _writer =[[DJVideoWriter alloc]initWithFilePath:filePath andSize:CGRectMake(0, 0, 1024, 768)];
    
    self.paintView.queue = self.queue;
    self.paintView.writer = self.writer;
    self.paintView.backgroundView =self.backgroundView;
    [self startTimer];
}

-(void)stopCapturing;{
    [self stopTimer];
}

-(void)stopTimer{
    NSLog(@" Stop ");
    if(self.timer.isValid)    [self.timer invalidate];
}

-(void)startTimer{
    NSLog(@" Start ");
    
    if(!self.timer.isValid){
        NSTimeInterval frameInterval = (1.0 / self.frameRate);
        self.timer = [NSTimer scheduledTimerWithTimeInterval:frameInterval
                                                          target:self
                                                        selector:@selector(captureFrame:)
                                                        userInfo:nil
                                                         repeats:YES];
        [[NSRunLoop mainRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
        [_writer startRecording];
    }
}


-(void)captureFrame:(NSTimer *)timer{
    //check if
//    NSOperationQueue * weakqueue = self.queue;
//    id weakSelf = self;
//    id backgroundView = self.backgroundView;
    _frameCount ++;
   
      if(_frameCount >200){
        [self stopCapturing];
        _markedToStop = YES;
    }
    
    DrawingOperation * dop = [[DrawingOperation alloc]init];
    dop.backgroundView = self.backgroundView;
    
//    dop.path = _path;
//    dop.frameCount = count;
    dop.date = [NSDate date];
    dop.size = self.entireView.bounds.size;
    dop.entireView = self.entireView;
    
    dop.touch = YES;
    dop.block=^(UIImage * image, NSDate * date, NSString * touch){
        [_writer writeVideoFrameAtTime:date image:image andTouch:touch];
        
    };
    [self.queue addOperation:dop];
    
   
//    [self.paintView setNeedsDisplay];
    
//    if(self.paintView.touches){
        
//         self.paintView.getOperationBlock = ^(NSOperation * operation){
//             [(DrawingOperation *)operation setBlock:^(UIImage * image, NSDate * date){
//                 //[NSThread sleepForTimeInterval:0.01f];
//                 [[weakSelf writer] writeVideoFrameAtTime:date image:image];
//                 
//             }];
//             
//             [(DrawingOperation *) operation setBackgroundView:[weakSelf backgroundView]];
//             [weakqueue addOperation:operation];
//         };

//    }
//    else{
//        DrawingOperation *operation = [[DrawingOperation alloc]init];
//        operation.date = [NSDate date];
//        operation.size = self.captureView.bounds.size;
//        operation.paintView = self.backgroundView;
//        operation.touch = NO;
//        operation.frameCount = _frameCount;
//        __weak DrawingOperation * o = operation;
//        NSDate * _date = operation.date;
//        
//        [operation setBlock:^(UIImage * image, NSDate * date, NSString * touch){
//            // send it to the writer
//            assert([date isEqual:_date]);
//            
//            
//            [NSThread sleepForTimeInterval:0.01f];
//            [[weakSelf writer] writeVideoFrameAtTime:o.date image:image andTouch:touch];
//            NSLog(@"NT");
//            
//        }];
//        [weakqueue addOperation:operation];
//    }
 }






@end
