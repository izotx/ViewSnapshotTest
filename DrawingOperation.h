//
//  DrawingOperation.h
//  ViewSnapshotTest
//
//  Created by sadmin on 1/11/14.
//  Copyright (c) 2014 DJMobileInc. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^NewCompletionBlock) (UIImage *image, NSDate * date, NSString * touch);
@interface DrawingOperation : NSOperation

@property (nonatomic, copy) UIBezierPath * path;
@property (nonatomic, copy) NSDate * date;
@property CGSize size;
@property int frameCount;
@property (nonatomic,strong) UIView * paintView;
@property (nonatomic,strong) UIView * backgroundView;
@property (nonatomic,strong) UIView * entireView;

@property (nonatomic,copy)   NewCompletionBlock block;
@property BOOL touch;

@property  CALayer * layer;




@end
