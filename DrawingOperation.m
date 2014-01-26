//
//  DrawingOperation.m
//  ViewSnapshotTest
//
//  Created by sadmin on 1/11/14.
//  Copyright (c) 2014 DJMobileInc. All rights reserved.
//

#import "DrawingOperation.h"

@implementation DrawingOperation


- (void)main {
    if ([self isCancelled]) {

    }
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0);
    if(self.entireView){
        CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
        [self.entireView drawViewHierarchyInRect:rect afterScreenUpdates:NO];
    }
    
    //CGContextRef context = UIGraphicsGetCurrentContext();
 
    //that would be drawing an entire view with the scroll view, background view and etc.
//    if(self.backgroundView){
//        CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
//        [self.backgroundView drawViewHierarchyInRect:rect afterScreenUpdates:NO];
//    }

    if(self.paintView){
        CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
        [self.paintView drawViewHierarchyInRect:rect afterScreenUpdates:NO];
    }
    
    if(self.path){
        // adding a background
        if(self.backgroundView){
            CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
            [self.backgroundView drawViewHierarchyInRect:rect afterScreenUpdates:NO];
        }
        [self.path stroke];
    }
//    if(self.layer){
//        CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
//        CGContextDrawLayerInRect(context, rect, self.layer);
//    }
    
//    NSTimeInterval  ti =    [self.date timeIntervalSince1970];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    NSData * d = UIImageJPEGRepresentation(image, 0.8);
//    [self save:d forFrame:ti * 1000.0];

    UIGraphicsEndImageContext();

    if(self.block){
        self.block(image,self.date, [NSString stringWithFormat:@"%d",self.touch]);
    
    }
   }

-(void)save:(NSData *)data forFrame:(double)frame{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *fileArray = [fileManager URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask];
    NSString *filePath = [NSString stringWithFormat:@"%@%fcache.jpg", [fileArray lastObject],frame];
    NSURL *fileUrl = [NSURL URLWithString:filePath];
    [data writeToURL:fileUrl atomically:YES];
}




@end
