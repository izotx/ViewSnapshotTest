//
//  LinearInterpView.h
//  FreehandDrawingTut
//
//  Created by A Khan on 11/10/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DJVideoWriter.h"

typedef void (^getOperation)(NSOperation * operation);
typedef void (^touchesBlock)();

@interface LinearInterpView : UIView 
@property BOOL touches;
@property (nonatomic, copy) getOperation getOperationBlock;
@property (nonatomic, copy) touchesBlock touchesBlock;
@property (nonatomic, strong) NSOperationQueue * queue;
@property (nonatomic, strong) DJVideoWriter * writer;
@property (nonatomic,strong) UIView * backgroundView;
@property CGPoint offset;
@property float scale;


@end
