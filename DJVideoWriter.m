//
//  DJVideoWriter.m
//  ViewSnapshotTest
//
//  Created by sadmin on 1/12/14.
//  Copyright (c) 2014 DJMobileInc. All rights reserved.
//

#import "DJVideoWriter.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/UTCoreTypes.h>
enum writerStatus {
    kWriterReady,
    kWriterWriting,
    KWriterCompleted
};


@interface DJVideoWriter(){
    void* bitmapData;
    int count ;
}
    @property (nonatomic, strong) AVAssetWriter *videoWriter;
    @property (nonatomic, strong) AVAssetWriterInput *videoWriterInput;
    @property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *avAdaptor;
    @property (nonatomic, strong) NSDate * startedAt;
    @property (nonatomic, strong) NSURL * fileURL;
    @property CGRect viewRect;
    @property CMTime currentTime; //for storing information about timestamp of last recorded timeframe
    @property int status; //tracking the strus of the writer
    @property BOOL ready;



@end

@implementation DJVideoWriter

//
-(instancetype)initWithFilePath:(NSString *)path andSize:(CGRect)viewRect{
    self = [super init];

    if(self){
        self.outputPath = path;
        self.viewRect =viewRect;
        self.ready = NO;
        [self setup];

    }
    return self;
}


//start recording
-(void)startRecording;{
    _startedAt = [NSDate date];
    
}

//stop recording
-(void)stopRecording;{
    [self completeRecordingSession];
}

-(void)setup{
    count = 0;
	_videoWriter = nil;
	_videoWriterInput = nil;
	_avAdaptor = nil;
	_startedAt = nil;
	bitmapData = NULL;
    
    [self setUpWriter];
    self.ready = YES;
    
}

-(void)cleanup{
    self.avAdaptor = nil;
	self.videoWriterInput = nil;
    self.videoWriter = nil;
	self.startedAt = nil;
    
	
	if (bitmapData != NULL) {
		free(bitmapData);
		bitmapData = NULL;
	}
}


// Creates an image in the bitmap context (It should be executed in the background)
-(CGImageRef)getImageFromImage:(UIImage *)rawimage{

    CGContextRef    context = NULL;
	CGColorSpaceRef colorSpace;
	int             bitmapByteCount;
	int             bitmapBytesPerRow;
	float height =self.viewRect.size.height;
    float width = self.viewRect.size.width;
    
	bitmapBytesPerRow   = (width * 4);
	bitmapByteCount     = (bitmapBytesPerRow * height);
	colorSpace = CGColorSpaceCreateDeviceRGB();
	if (bitmapData != NULL) {
		free(bitmapData);
	}
	bitmapData = malloc( bitmapByteCount );
	if (bitmapData == NULL) {
		fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
		return NULL;
	}
	
	context = CGBitmapContextCreate (bitmapData,
									 width,
									 height,
									 8,      // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
	
	CGContextSetAllowsAntialiasing(context,NO);
	if (context== NULL) {
		free (bitmapData);
		fprintf (stderr, "Context not created!");
        CGColorSpaceRelease( colorSpace );
		return NULL;
	}
	CGColorSpaceRelease( colorSpace );
    CGContextDrawImage(context, self.viewRect, rawimage.CGImage);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);

	//UIImage* background = [UIImage imageWithCGImage: cgImage];
	//CGImageRelease(cgImage);
	CGContextRelease(context);
    return cgImage;
    //return background;
}


//reset the ivars
- (void) cleanupWriter {
    
	self.avAdaptor = nil;
	self.videoWriterInput = nil;
    self.videoWriter = nil;
	self.startedAt = nil;
    
	
	if (bitmapData != NULL) {
		free(bitmapData);
		bitmapData = NULL;
	}
}


-(BOOL) setUpWriter {
	NSError* error = nil;
   
    assert(self.outputPath);
    
	self.fileURL = [NSURL URLWithString:self.outputPath];
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:self.fileURL fileType:AVFileTypeQuickTimeMovie error:&error];
	NSParameterAssert(_videoWriter);
    
   //[_videoWriter addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
	
	//Configure video
	NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithDouble:1024.0*1024.0], AVVideoAverageBitRateKey,
										   nil ];
	
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
								   AVVideoCodecH264, AVVideoCodecKey,
								   [NSNumber numberWithInt:self.viewRect.size.width], AVVideoWidthKey,
								   [NSNumber numberWithInt:self.viewRect.size.height], AVVideoHeightKey,
								   videoCompressionProps, AVVideoCompressionPropertiesKey,
								   nil];
	
	self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
	
	NSParameterAssert(self.videoWriterInput);
    //self.videoWriterInput.expectsMediaDataInRealTime = YES;
    
    NSDictionary* bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    
    
    
	
	self.avAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput sourcePixelBufferAttributes:bufferAttributes];
	
	//add input
	[_videoWriter addInput:self.videoWriterInput];
	[_videoWriter startWriting];
	[_videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
    
	return YES;
}

- (void) completeRecordingSession {
    if(!self.ready) return;
    
     self.ready = NO;
     [self.videoWriterInput markAsFinished];
    
        // Wait for the video
       AVAssetWriterStatus status = _videoWriter.status;
        while (status == AVAssetWriterStatusUnknown) {
            [NSThread sleepForTimeInterval:0.1f];
            status = _videoWriter.status;
        }
        
        [_videoWriter finishWritingWithCompletionHandler:^{
            
            if(_videoWriter.status == AVAssetWriterStatusFailed)
            {
                NSLog(@"Video Writer Failed");
            }
            if(_videoWriter.status == AVAssetWriterStatusCompleted){
                NSLog(@"Video Finished Writing. Completed ");
              
            }
        }];    
}

-(void)save:(NSData *)data forFrame:(double)frame andTouch: (NSString *)touch{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *fileArray = [fileManager URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask];
    NSString *filePath = [NSString stringWithFormat:@"%@%fcache%@.jpg", [fileArray lastObject],frame,touch];

    NSURL *fileUrl = [NSURL URLWithString:filePath];
    [data writeToURL:fileUrl atomically:YES];
}



-(void) writeVideoFrameAtTime:(NSDate *)date  image:(UIImage *)frame andTouch:(NSString * )touch{

    float timeElapsed = [date timeIntervalSinceDate: self.startedAt] * 1000.0;
    NSLog(@"Time Elapsed :%.2f",timeElapsed);
    CMTime   time = CMTimeMake(timeElapsed, 1000);
    
   // [self save:UIImageJPEGRepresentation(frame, 0.5) forFrame:timeElapsed andTouch:touch];

    if(self.ready == NO){
        return;
    }

    if([[NSThread currentThread]isMainThread]){
        NSLog(@"Main Thread ");
    }
    
   
    
    if (![_videoWriterInput isReadyForMoreMediaData]) {
        NSLog(@"Not ready for video data");
	}
	else {
		@synchronized (self) {
            
           // @try {
                if(!frame) return;
                CGImageRef frameI = [self getImageFromImage:frame];
                CVPixelBufferRef pixelBuffer = NULL;
            
                CGImageRef cgImage = CGImageCreateCopy(frameI);
                CGImageRelease(frameI);
            
                
                CFDataRef image = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
                
                int status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, self.avAdaptor.pixelBufferPool, &pixelBuffer);
                
                if(status != 0){
                    //could not get a buffer from the pool
                    NSLog(@"Error creating pixel buffer:  status=%d", status);
                }
                // set image data into pixel buffer
                CVPixelBufferLockBaseAddress(pixelBuffer, 0 );
                uint8_t* destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
                
                CFDataGetBytes(image, CFRangeMake(0, CFDataGetLength(image)), destPixels);  //XXX:  will work if the pixel buffer is contiguous and has the same bytesPerRow as the input data
                
                if(status == 0){
                    BOOL success = [self.avAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
                    if (!success) NSLog(@"Warning:  Unable to write buffer to video");
                    
                    self.currentTime = time;
                }
                //clean up
                CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
                CVPixelBufferRelease( pixelBuffer );
                CFRelease(image);
                CGImageRelease(cgImage);
            
		}		
	}	
}




- (void)dealloc {
	[self cleanupWriter];
    
    
}




@end
