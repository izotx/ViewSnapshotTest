//
//  DJVideoWriter.h
//  ViewSnapshotTest
//
//  Created by sadmin on 1/12/14.
//  Copyright (c) 2014 DJMobileInc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface DJVideoWriter : NSObject


@property (nonatomic,strong) NSString * outputPath;
-(void) writeVideoFrameAtTime:(NSDate *)time  image:(UIImage *)frame andTouch:(NSString * )touch;
-(instancetype)initWithFilePath:(NSString *)path andSize:(CGRect)viewRect;
-(void)startRecording;
-(void)stopRecording;

@end
