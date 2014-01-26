#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


/**
 * Delegate protocol.  Implement this if you want to receive a notification when the
 * view completes a recording.
 *
 */
@protocol ScreenCaptureViewDelegate <NSObject>
- (void) recordingFinished:(BOOL)success;
- (void) recordingInterrupted;

@optional
-(void)previewUpdated:(UIImage *)img;
- (void) recordingStartedNotification;
@end


@interface ScreenCaptureView : UIView<AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate> {
	//video writing

	AVAssetWriterInput *videoWriterInput;
	AVAssetWriterInputPixelBufferAdaptor *avAdaptor;
	
	//recording state
	NSDate* startedAt;
	void* bitmapData;
    NSString *outputPath;
}

//for recording video
- (bool) startRecording;
- (void) stopRecording;

//
-(void)addVideoPreview;
-(void)removeVideoPreview;
-(void)switchCamera;

//for accessing the current screen and adjusting the capture rate, etc.
@property(retain) UIImage* currentScreen;
@property(assign) float frameRate;
@property(nonatomic, assign) id<ScreenCaptureViewDelegate> delegate;
@property(nonatomic,retain) NSString *outputPath;

@property(nonatomic,strong) UIImage * vi;//video preview
@property (nonatomic, strong)AVAssetWriter *videoWriter;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic,strong) UIView * paintView;

@property CGRect  videoPreviewFrame;
@property BOOL fullScreen;
@property BOOL rotatePreview;
@property BOOL ready;
@property BOOL recording;
@property BOOL completed;

//- (void) writeVideoFrameAtTime:(CMTime)time;

@end