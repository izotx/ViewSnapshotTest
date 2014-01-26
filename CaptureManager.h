//
//  CaptureManager.h
//  ViewSnapshotTest
//
//  Created by sadmin on 1/11/14.
//  Copyright (c) 2014 DJMobileInc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LinearInterpView;

@interface CaptureManager : NSObject

@property (nonatomic,strong) LinearInterpView * paintView; //paint view
@property (nonatomic,strong) UIView * backgroundView; // whataver is in the background
@property (nonatomic,strong) UIView * captureView; // scroll view
@property (nonatomic,strong) UIView * entireView;


-(void)startCapturing;
-(void)stopCapturing;


@end
