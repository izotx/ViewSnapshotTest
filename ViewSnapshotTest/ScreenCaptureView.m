#import "ScreenCaptureView.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "DrawingOperation.h"

@interface ScreenCaptureView()
{
    dispatch_queue_t myConcurrentDispatchQueue;
    int frameCount;
    NSOperationQueue * queue;
}
@property BOOL paused;
@property CMTime currentCMTime;
@property CGLayerRef destLayer;
@property CGContextRef destContext;
@property BOOL layerReady;
@property NSTimer *captureTimer;
//- (void) writeVideoFrameAtTime:(CMTime)time;
@end

@implementation ScreenCaptureView

@synthesize currentScreen, frameRate, delegate;

@synthesize outputPath;
@synthesize vi;

@synthesize panGesture;
@synthesize videoPreviewFrame;
@synthesize fullScreen;
@synthesize rotatePreview;



- (void) initialize {
	self.frameRate = 20;     //frames per second
	 myConcurrentDispatchQueue = dispatch_queue_create( "com.example.gcd.MyConcurrentDispatchQueue", DISPATCH_QUEUE_CONCURRENT);
    frameCount = 0;
	_videoWriter = nil;
	videoWriterInput = nil;
	avAdaptor = nil;
	startedAt = nil;
	bitmapData = NULL;
    self.userInteractionEnabled = YES;
    queue = [[NSOperationQueue alloc]init];
    queue.maxConcurrentOperationCount =1;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseAction:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeAction:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    _layerReady = NO;
    _ready = YES;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"Dictionary Change :%@",change);
}

-(void)statusChanged:(NSNotification *)notification{
    NSLog(@"Notification %@",notification);
}

-(void)pauseAction:(NSNotification * )notification{
        [delegate recordingInterrupted];
}

-(void)activeAction:(NSNotification * )notification{
    //paused=NO;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initialize];
	}
	return self;
}

- (id) init {
	self = [super init];
	if (self) {
		[self initialize];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self initialize];
	}
	return self;
}

/*
- (CGContextRef) createBitmapContextOfSize:(CGSize) size {
	CGContextRef    context = NULL;
	CGColorSpaceRef colorSpace;
	int             bitmapByteCount;
	int             bitmapBytesPerRow;
	
	bitmapBytesPerRow   = (size.width * 4);
	bitmapByteCount     = (bitmapBytesPerRow * size.height);
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
									 size.width,
									 size.height,
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
	
	return context;
}
*/

-(void)save:(NSData *)data forFrame:(int)frame{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *fileArray = [fileManager URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask];
    NSString *filePath = [NSString stringWithFormat:@"%@cache%d.jpg", [fileArray lastObject],frame];
    NSURL *fileUrl = [NSURL URLWithString:filePath];
    [data writeToURL:fileUrl atomically:YES];
}

-(UIImage *)getImage{
    
    if([NSThread isMainThread]){
        NSLog(@" main");
    }

    
UIGraphicsBeginImageContextWithOptions(self.paintView.bounds.size, YES, 0.0);
    CGContextRef icontext = UIGraphicsGetCurrentContext();
    //[self.paintView drawViewHierarchyInRect:self.paintView.bounds afterScreenUpdates:NO];
    //self.paintView.layer.shouldRasterize = YES;
    [self.paintView.layer.presentationLayer renderInContext:icontext];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
UIGraphicsEndImageContext();

    
    CGContextRef    context = NULL;
	CGColorSpaceRef colorSpace;
	int             bitmapByteCount;
	int             bitmapBytesPerRow;
	float height =self.paintView.bounds.size.height;
    float width = self.paintView.bounds.size.width;
    
    CGFloat contentScale = [[UIScreen mainScreen]scale];
    if(contentScale>1){
     //   height = height/2.0;
     //   width = width/2.0;
    }
    
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
    
   // CGContextRef c =    [self createBitmapContextOfSize:self.bounds.size];
    CGContextDrawImage(context, self.frame, image.CGImage);// image.CGImage);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
	UIImage* background = [UIImage imageWithCGImage: cgImage];
	CGImageRelease(cgImage);
	CGContextRelease(context);
    
    return background;
}

- (void)captureFrame:(NSTimer *)captureTimer
{
    frameCount ++;

    if(frameCount>550){
        [self stopRecording];
    
    }
   
    DrawingOperation * dr= [[DrawingOperation alloc]init];
    dr.paintView = self.paintView; //[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.paintView]];
    
    dr.size = self.paintView.bounds.size;
    dr.date = [NSDate new];
    dr.frameCount = frameCount;

//
//    dr.block = ^(UIImage * image, NSDate * date){
//        NSLog(@"Date %@",date);
//    };
    
  //  [queue addOperation:dr];
    
//    
//    [queue addOperationWithBlock:^{
//        float millisElapsed = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
//        //NSDate* start = [NSDate date];
//        //float delayRemaining=0;
//        
//       // float processingSeconds = [[NSDate date] timeIntervalSinceDate:start];
//       // float delayRemaining1 = (1.0 / self.frameRate) - processingSeconds;
//       // delayRemaining = (delayRemaining > 0.0)? delayRemaining1 : 0.01;
//        UIImage * im = [self getImage];
//// self.currentScreen = [self getImage];
//        
//        if (_recording) {
//            
//            [self writeVideoFrameAtTime:CMTimeMake((int)millisElapsed, 1000) image:im];
//        }
//    }];
//    
    
//    dispatch_async(myConcurrentDispatchQueue, ^{
//         float millisElapsed = [[NSDate date] timeIntervalSinceDate:startedAt] * 1000.0;
//        NSDate* start = [NSDate date];
//        float delayRemaining=0;
//        
//        float processingSeconds = [[NSDate date] timeIntervalSinceDate:start];
//        float delayRemaining1 = (1.0 / self.frameRate) - processingSeconds;
//        delayRemaining = (delayRemaining > 0.0)? delayRemaining1 : 0.01;
//        
//        self.currentScreen = [self getImage];
//        
//        if (_recording) {
//           
//            [self writeVideoFrameAtTime:CMTimeMake((int)millisElapsed, 1000)];
//        }
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//          //  [self performSelector:@selector(captureFrame:) withObject:nil afterDelay:delayRemaining];
//        });
//    });
//
    
  
    
    
    
   	
}


- (void) cleanupWriter {

	avAdaptor = nil;
	videoWriterInput = nil;
    _videoWriter = nil;
	startedAt = nil;
    
	
	if (bitmapData != NULL) {
		free(bitmapData);
		bitmapData = NULL;
	}
   
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name: UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name: UIApplicationWillResignActiveNotification object:nil];
     NSLog(@"Clean Up Writer");
}

- (void)dealloc {
	[self cleanupWriter];
    
   
}

- (NSURL*) tempFileURL {
    int ran = arc4random()%100* arc4random();
	self.outputPath = [[NSString alloc] initWithFormat:@"%@/temp_piece%d.mp4", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0],ran];
	NSURL* outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
	NSFileManager* fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:outputPath]) {
		NSError* error;
		if ([fileManager removeItemAtPath:outputPath error:&error] == NO) {
			NSLog(@"Could not delete old recording file at path:  %@", outputPath);
		}
	}
	
	return outputURL;
}

-(BOOL) setUpWriter {
  //  NSLog(@"Set Up Writer");
	NSError* error = nil;
	self.videoWriter = [[AVAssetWriter alloc] initWithURL:[self tempFileURL] fileType:AVFileTypeQuickTimeMovie error:&error];
	NSParameterAssert(_videoWriter);
    
    
    [_videoWriter addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
	
	//Configure video
	NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithDouble:1024.0*1024.0], AVVideoAverageBitRateKey,
										   nil ];
	
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
								   AVVideoCodecH264, AVVideoCodecKey,
								   [NSNumber numberWithInt:self.frame.size.width], AVVideoWidthKey,
								   [NSNumber numberWithInt:self.frame.size.height], AVVideoHeightKey,
								   videoCompressionProps, AVVideoCompressionPropertiesKey,
								   nil];
	
	videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
	
	NSParameterAssert(videoWriterInput);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    
    NSDictionary* bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
 
    
    
	
	avAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:bufferAttributes];
	
	//add input
	[_videoWriter addInput:videoWriterInput];
	[_videoWriter startWriting];
	[_videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];

	return YES;
}

- (void) completeRecordingSession {
	
    @autoreleasepool {
        NSLog(@"Complete recording session ");
	@try {
        [videoWriterInput markAsFinished];
        NSLog(@"Mark recording as finished ");
    }
    @catch (NSException *exception) {
        NSLog(@" Mark as Finished Failed: %@",[exception debugDescription]);
    }
    @finally {
        
    }

        
    // Wait for the video
	int status = _videoWriter.status;
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
            self.completed = YES;
            _ready = YES;
             //[self cleanupWriter];
        }
        
        
        }];
	}
}



- (bool) startRecording {
    _completed = NO;
     _ready = NO;
	bool result = NO;
	@synchronized(self) {
		if (! _recording) {
			result = [self setUpWriter];
			startedAt = [NSDate date];
			_recording = true;

			NSTimeInterval frameInterval = (1.0 / self.frameRate);
	  		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:frameInterval
															  target:self
															selector:@selector(captureFrame:)
															userInfo:nil
															 repeats:YES];
			self.captureTimer = timer;
      
            
            [self captureFrame:nil];
            
        }
    
        
	}
	return result;
}

- (void) stopRecording {
	@synchronized(self) {
		if (_recording) {
			[self.captureTimer invalidate];
			self.captureTimer = nil;
			
			_recording = false;
            if([_videoWriter respondsToSelector:@selector(finishWritingWithCompletionHandler:)]){
            
                [self completeRecordingSession];
            }
        }
	}
}

-(void) writeVideoFrameAtTime:(CMTime)time  image:(UIImage *)frame{
    
    
    if(self.paused) return;
    
    if (![videoWriterInput isReadyForMoreMediaData]) {
		  NSLog(@"Not ready for video data");
	}
	else {
		@synchronized (self) {
		
            @try {
                
                if(!frame) return;
                
                CVPixelBufferRef pixelBuffer = NULL;
                CGImageRef cgImage = CGImageCreateCopy([frame CGImage]);
                
                CFDataRef image = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
                
                int status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, avAdaptor.pixelBufferPool, &pixelBuffer);
                if(status != 0){
                    //could not get a buffer from the pool
                    NSLog(@"Error creating pixel buffer:  status=%d", status);
                }
                // set image data into pixel buffer
                CVPixelBufferLockBaseAddress(pixelBuffer, 0 );
                uint8_t* destPixels = CVPixelBufferGetBaseAddress(pixelBuffer);
               
                CFDataGetBytes(image, CFRangeMake(0, CFDataGetLength(image)), destPixels);  //XXX:  will work if the pixel buffer is contiguous and has the same bytesPerRow as the input data
                
                if(status == 0){
                    BOOL success = [avAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
                    if (!success) NSLog(@"Warning:  Unable to write buffer to video");
                    
                    self.currentCMTime = time;
                }
                //clean up
                CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
                CVPixelBufferRelease( pixelBuffer );
                CFRelease(image);
                CGImageRelease(cgImage);
            }
            @catch (NSException *exception) {
                NSLog(@"exception %@",exception.debugDescription);
            }
            @finally {
                
            }
           
		}		
	}	
}

//Handling Video Preview
-(void)addVideoPreview{
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // Create a UIImage from the sample buffer data
    UIImage * im = [self imageFromSampleBuffer:sampleBuffer];
    self.vi = im;
    [delegate previewUpdated:vi]
    ;}


- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
      // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
      
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, self.frame.size.height);
    CGContextConcatCTM(context, flipVertical);
    
    //videoPreviewImage = quartzImage;
    //CGImageRelease(quartzImage);
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

-(void)switchCamera{
  
}

-(void)removeVideoPreview{
  
}




@end