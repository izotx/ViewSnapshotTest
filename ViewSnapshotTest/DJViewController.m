//
//  DJViewController.m
//  ViewSnapshotTest
//
//  Created by sadmin on 9/22/13.
//  Copyright (c) 2013 DJMobileInc. All rights reserved.
//

#import "DJViewController.h"
#import "ScreenCaptureView.h"
#import "CaptureManager.h"
#import  "LinearInterpView.h"

@interface DJViewController ()<UIScrollViewDelegate>
{
    int count;
    dispatch_queue_t myConcurrentDispatchQueue;
}
- (IBAction)scrollingOff:(id)sender;
- (IBAction)scrollingOn:(id)sender;
@property float frameRate;
@property(nonatomic,strong) ScreenCaptureView * screencapture;
@property (nonatomic,strong) CaptureManager * captureManager;
@property (strong, nonatomic) IBOutlet LinearInterpView *paintView;
@property (strong, nonatomic) IBOutlet UIView *allView;


@property (strong, nonatomic) IBOutlet UIImageView *backgroundView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;



@end




@implementation DJViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    count = 0;
    self.frameRate = 60.f;
    myConcurrentDispatchQueue = dispatch_queue_create( "com.example.gcd.MyConcurrentDispatchQueue", DISPATCH_QUEUE_CONCURRENT);
  
        self.scrollView.delegate = self;
    
    
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    _screencapture = [[ScreenCaptureView alloc]initWithFrame:self.view.bounds];
    _screencapture.paintView = self.view;
    _captureManager = [[CaptureManager alloc]init];
//   _captureManager.paintView = self.paintView;
//    _captureManager.captureView = self.view;
//    _captureManager.backgroundView = self.view;
    _captureManager.entireView = self.view;
    [self scrollingOn:Nil];
    
    
    [_captureManager startCapturing];
    
    
    
    

}

- (NSUInteger) supportedInterfaceOrientations
{
    //Because your app is only landscape, your view controller for the view in your
    // popover needs to support only landscape
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)save:(NSData *)data forFrame:(int)frame{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *fileArray = [fileManager URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask];
    NSString *filePath = [NSString stringWithFormat:@"%@cache%d.jpg", [fileArray lastObject],frame];
    NSURL *fileUrl = [NSURL URLWithString:filePath];
    [data writeToURL:fileUrl atomically:YES];
}


-(UIImage *)getSnap{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 0.0);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
   // NSData * d = UIImageJPEGRepresentation(image, 0.5);
    UIGraphicsEndImageContext();

    return image;
}

-(void)createSnapshot{

    dispatch_async(myConcurrentDispatchQueue, ^{
        
        NSDate* start = [NSDate date];
        float delayRemaining=0;
         
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 0.0);
        [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:NO];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        NSData * d = UIImageJPEGRepresentation(image, 0.5);
        UIGraphicsEndImageContext();
        [self save:d  forFrame:count];
        NSLog(@"bpr %zu",
              CGImageGetBytesPerRow(image.CGImage));
        

        count ++;

        float processingSeconds = [[NSDate date] timeIntervalSinceDate:start];
        float delayRemaining1 = (1.0 / self.frameRate) - processingSeconds;
        delayRemaining = (delayRemaining > 0.0)? delayRemaining1 : 0.001;
        
        NSLog(@"%d %f",count,delayRemaining );
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(createSnapshot) withObject:nil afterDelay:delayRemaining];
        });
    });
}


- (IBAction)scrollingOff:(id)sender {
    self.scrollView.scrollEnabled = NO;
    [self.view addSubview: self.backgroundView];
    [self.view addSubview: self.paintView];
    
}

- (IBAction)scrollingOn:(id)sender {
  //  self.allView = [[UIView alloc]initWithFrame:self.view.bounds];
  //  self.allView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.scrollView.scrollEnabled = NO;
    self.backgroundView.contentMode = UIViewContentModeScaleAspectFit;
    [self.allView addSubview:self.backgroundView];
    [self.allView addSubview:self.paintView];

   // self.allView.bounds =self.paintView.bounds;
    
    [self.scrollView addSubview: self.allView];
    self.scrollView.contentSize =self.view.bounds.size;
    self.scrollView.minimumZoomScale = 0.3;
    self.scrollView.maximumZoomScale = 2;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;  {
  //  self.allView.contentMode = UIViewContentModeScaleAspectFit;
    return self.allView;
}




@end
