#import "LinearInterpView.h"
#import "DrawingOperation.h"
@interface LinearInterpView()
    @property(nonatomic,strong) NSDate * lastDate;

@end


@implementation LinearInterpView
{
    UIBezierPath *path; // (3)
        int count;
    NSMutableArray * mutableArray;
    dispatch_queue_t dqueue;// = dispatch_queue_create("com.example.MyQueue", NULL);
    
}

- (id)initWithCoder:(NSCoder *)aDecoder // (1)
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setMultipleTouchEnabled:NO]; // (2)
        [self setBackgroundColor:[UIColor whiteColor]];
        path = [UIBezierPath bezierPath];
        [path setLineWidth:2.0];
        path.lineJoinStyle = kCGLineJoinRound;
      //  queue = [[NSOperationQueue alloc]init];
        //queue.maxConcurrentOperationCount =1;
        
        count = 0;
        mutableArray = [NSMutableArray new];
         dqueue = dispatch_queue_create("com.example.MyQueue", NULL);
        [self setBackgroundColor:[UIColor clearColor]];
        self.opaque = NO;
        self.touches = NO;
        self.lastDate = [NSDate new];
        
        
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [[UIColor whiteColor] setStroke];
    [path stroke];

    
    CGPathRef newp=   CGPathCreateCopy(path.CGPath);
    UIBezierPath * _path = [UIBezierPath bezierPathWithCGPath:newp];
    
    DrawingOperation * dop = [[DrawingOperation alloc]init];
    dop.backgroundView = self.backgroundView;
    
    dop.path = _path;
    dop.frameCount = count;
    dop.date = [NSDate date];
    dop.size = self.bounds.size;
    dop.touch = YES;
    dop.block=^(UIImage * image, NSDate * date, NSString * touch){
        [_writer writeVideoFrameAtTime:date image:image andTouch:touch];
    
    };
    
  //  [self.queue addOperation:dop];
   
    

    
    
    
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [path moveToPoint:p];
    self.touches = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    self.touches = YES;
    
    count ++;
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [path addLineToPoint:p]; // (4)

    //get a copy
//    CGPathRef newp=   CGPathCreateCopy(path.CGPath);
//    UIBezierPath * _path = [UIBezierPath bezierPathWithCGPath:newp];
//    
//    DrawingOperation * dop = [[DrawingOperation alloc]init];
//    dop.path = _path;
//    dop.frameCount = count;
//    dop.date = [NSDate date];
//    dop.size = self.bounds.size;
//    
//    if(self.getOperationBlock){
//        self.getOperationBlock(dop);
//    }
//
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    //[self touchesMoved:touches withEvent:event];
   // self.touchesBlock();
    self.touches = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    //[self touchesEnded:touches withEvent:event];
    //self.touchesBlock();
    self.touches = NO;
}

-(void)save:(NSData *)data forFrame:(int)frame{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *fileArray = [fileManager URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask];
    NSString *filePath = [NSString stringWithFormat:@"%@cache%d.jpg", [fileArray lastObject],frame];
    NSURL *fileUrl = [NSURL URLWithString:filePath];
    [data writeToURL:fileUrl atomically:YES];
}


@end
