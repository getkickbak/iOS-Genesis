/* (c) 2009 eBay Inc. */

#import <UIKit/UIKit.h>
#import "AudioToolbox/AudioServices.h"
#import <QuartzCore/QuartzCore.h>

@class OverlayControllerNigma;

/*******************************************************************************
 OverlayControllerNigmaDelegate
 
 The delegate receives messages about the results of a scan. This method
 gets called when a scan session completes.	
 */
@protocol OverlayControllerNigmaDelegate <NSObject>
@optional
- (void) overlayController:(OverlayControllerNigma*)overlay 
             returnResults:(NSSet *)results;
@end

/*******************************************************************************
 CameraViewController
 
 An view that is places the camera view.
*/
@interface CameraViewController : UIViewController
{
}
@property (assign) OverlayControllerNigma *overlay;
- (void) startScanner;
@end

/*******************************************************************************
 OverlayControllerNigma
 
 An overlay view that is places ontop of the camera view.
 */
@interface OverlayControllerNigma : UIViewController
{
	
	IBOutlet UILabel * textCue;
	
	IBOutlet UIImageView * redlaserLogo;
	
	BOOL isGreen;
	
	SystemSoundID _scanSuccessSound;
	BOOL _isSilent;
	
	IBOutlet UILabel * latestResultLabel;

	IBOutlet UIBarButtonItem *flashButton;
	IBOutlet UIToolbar *toolBar;
	IBOutlet UIBarButtonItem *cancelButton;
	
	// Rectangle
	CAShapeLayer *_rectLayer;
   
   // i-Nigma
   void* m_pScanner;
   int m_bTorch;
   CameraViewController *camera;
}

@property (assign) CameraViewController *camera;
@property (retain) id <OverlayControllerNigmaDelegate> delegate;
-(IBAction) cancelPressed;
-(IBAction) flashPressed;
-(void) onError: (const char*) str;
-(void) onNotify: (const char*) str;
-(void) onDecode: (const unsigned short*) str:(const char*) strType;
-(void) OnCameraStopOrStart:(int) on;
-(void *)getScanner;
-(int) getBTorch;
-(void) setScanner: (void *)scanner;
-(void) setBTorch: (int)on;

-(void) beepOrVibrate;
- (CGMutablePathRef)newRectPathInRect:(CGRect)rect;
- (void) setActiveRegionRect;

@end

