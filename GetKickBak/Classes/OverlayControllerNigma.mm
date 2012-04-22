/* (c) 2009 eBay Inc. */

#if defined(RL_LOCALIZED)
#import "Localization.h"
#endif
#import "OverlayControllerNigma.h"
#import "Scanner.h"

void WrapError(void* pThis,const char* str)
{
	//OverlayControllerNigma* p = ((__bridge_transfer CameraViewController*)pThis).overlay;
	OverlayControllerNigma* p = ((__bridge OverlayControllerNigma*)pThis);
	[p onError:str];
	
}
void WrapNotify(void* pThis,const char* str)
{
	//OverlayControllerNigma* p = ((__bridge_transfer CameraViewController*)pThis).overlay;
	OverlayControllerNigma* p = ((__bridge OverlayControllerNigma*)pThis);
	[p onNotify:str];
	
}
void WrapDecode(void* pThis,const unsigned short* str,const char* SymbolType)
{
	//OverlayControllerNigma* p = ((__bridge_transfer CameraViewController*)pThis).overlay;   
	OverlayControllerNigma* p = ((__bridge OverlayControllerNigma*)pThis);
	[p onDecode:str:SymbolType];
}
void WrapCameraStopOrStart(int on,void* pThis)
{
	//OverlayControllerNigma* p = ((__bridge_transfer CameraViewController*)pThis).overlay;
	OverlayControllerNigma* p = ((__bridge OverlayControllerNigma*)pThis);
	[p OnCameraStopOrStart:on];	
}

@implementation CameraViewController
@synthesize overlay;

- (void)viewWillAppear:(BOOL)animated
{
   if (![overlay getScanner])
   {
      CScanner *scanner = new CScanner((__bridge void *)overlay);
      [overlay setScanner:(void *)scanner];
      [overlay setBTorch:0];      
      NSLog(@"Scanner Loading ...");
      [self startScanner];
   }
}

-(void)startScanner
{
   // Start Scan upon Ready
   NSLog(@"Scanner Loading Into View");
   CScanner *scanner = (CScanner *)[overlay getScanner];   
   scanner->Scan((__bridge  void*)self);   
}
@end

@implementation OverlayControllerNigma
@synthesize camera;
@synthesize delegate;

// Checks if the phone is in vibrate mode, in which case the scanner
// vibrates instead of beeps.

-(void)beepOrVibrate
{
	if(!_isSilent)
	{
		UInt32 routeSize = sizeof (CFStringRef);
		CFStringRef route = NULL;
		AudioSessionGetProperty (
								 kAudioSessionProperty_AudioRoute,
								 &routeSize,
								 &route
								 );
		
		if (CFStringGetLength(route) == 0) {
			AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
		}
		else {
			AudioServicesPlaySystemSound(_scanSuccessSound);
		}
	}
}

-(IBAction)cancelPressed
{
	[self onDecode:NULL:NULL];
}

-(IBAction)flashPressed 
{
	if ([flashButton style] == UIBarButtonItemStyleBordered) 
	{
		[flashButton setStyle:UIBarButtonItemStyleDone];
      m_bTorch = 1;
      ((CScanner*)m_pScanner)->TurnTorch(1);
	} 
	else 
	{
		[flashButton setStyle:UIBarButtonItemStyleBordered];
      m_bTorch = 0;
      ((CScanner*)m_pScanner)->TurnTorch(0);
	}
}

// Optionally, you can change the active scanning region.
// The region specified below is the default, and lines up
// with the default overlay.  It is recommended to keep the
// active region similar in size to the default region.
// Additionally, the iPhone 3GS may not focus as well if
// the region is too far away from center.
//
// In portrait mode only the top and bottom of this rectangle
// is used. The x-position and width specified are ignored.


- (void) setPortraitLayout
{	
	// Animate the UI changes
	CGAffineTransform transform = CGAffineTransformMakeRotation(0);
	//self.view.transform = transform;
	
	[UIView beginAnimations:@"rotateToPortrait" context:nil]; // Tell UIView we're ready to start animations.
	[UIView setAnimationDelegate:self];
	//[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationCurve: UIViewAnimationCurveLinear ];
	[UIView setAnimationDuration: 0.5];
	
	redlaserLogo.transform = transform;
	
	[self setActiveRegionRect];
	
	[UIView commitAnimations]; // Animate!
}

- (CGMutablePathRef)newRectPathInRect:(CGRect)rect 
{
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, rect);
	return path;
}

- (void) setActiveRegionRect
{
	[_rectLayer setFrame:CGRectMake(0, 100, 320, 250)];
	
	CGPathRef path = [self newRectPathInRect:_rectLayer.bounds];
	[_rectLayer setPath:path];
	CGPathRelease(path);
	[_rectLayer needsLayout];
}

- (void)viewDidLoad 
{
   [super viewDidLoad];
	isGreen = FALSE;
	
	// Create active region rectangle
	_rectLayer = [CAShapeLayer layer];
	_rectLayer.fillColor = [[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.2] CGColor];
	_rectLayer.strokeColor = [[UIColor whiteColor] CGColor];
	_rectLayer.lineWidth = 3;
	_rectLayer.anchorPoint = CGPointZero;
	[self.view.layer addSublayer:_rectLayer];
	
	self->_isSilent = [[NSUserDefaults standardUserDefaults] boolForKey:@"silent_pref"];
		
	if(!_isSilent) // If silent, no need to do this.
	{
		NSURL* aFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"] isDirectory:NO]; 
		AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)aFileURL, &_scanSuccessSound);
		
		UInt32 flag = 0;
		OSStatus error = AudioServicesSetProperty(kAudioServicesPropertyIsUISound,
												  sizeof(UInt32),
												  &_scanSuccessSound,
												  sizeof(UInt32),
												  &flag);
		
		float aBufferLength = 1.0; // In seconds
		error = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, 
								sizeof(aBufferLength), &aBufferLength);
		
		/* Create and warm up an audio session */
		AudioSessionInitialize(NULL, NULL, NULL, NULL);
		AudioSessionSetActive(TRUE);
	}
}

- (void)viewDidUnload 
{		
	AudioServicesDisposeSystemSoundID(_scanSuccessSound);
	if(!_isSilent) { AudioSessionSetActive(FALSE); }
}

- (void)viewWillAppear:(BOOL)animated
{
   [self setPortraitLayout];
   
   if (!((CScanner*)m_pScanner)->IsTorchAvailable())
	{
		[flashButton setEnabled:NO];
		NSMutableArray * items = [[toolBar items] mutableCopy];
		[items removeObject:flashButton];
		[toolBar setItems:items animated:NO];
		//[items release];
	}else
	{
		[flashButton setEnabled:YES];
		[flashButton setStyle:UIBarButtonItemStyleBordered];
	}

	textCue.text = @"";   
}

-(void) onError: (const char*) str
{
   NSString *myString = [[NSString alloc] initWithUTF8String:str];

	if ([myString isEqualToString:@"Camera in use Error"])
   {
   }
	else if ([myString isEqualToString:@"General Error"])
   {
   }
	else if ([myString isEqualToString:@"License Error"])
   {
   }
	else if ([myString isEqualToString:@"Code Invalid Error"])
   {
   }
	else if ([myString isEqualToString:@"Code Not Supported Error"])
   {
   }
}

-(void) onNotify: (const char*) str
{
   NSString *myString = [[NSString alloc] initWithUTF8String:str];
	if ([myString isEqualToString:@"License Process Failed"])
   {
      _rectLayer.strokeColor = [[UIColor whiteColor] CGColor];
   }
	else if ([myString isEqualToString:@"Camera Started"])
   {
      _rectLayer.strokeColor = [[UIColor whiteColor] CGColor];
   }
	else if ([myString isEqualToString:@"Getting License Started"])
   {
      _rectLayer.strokeColor = [[UIColor whiteColor] CGColor];
   }
	else if ([myString isEqualToString:@"Getting License Succeeded"])
   {
      _rectLayer.strokeColor = [[UIColor whiteColor] CGColor];
   }
	else if ([myString isEqualToString:@"Code Found"])
   {
      NSLog(@"QR Code Found!");
      _rectLayer.strokeColor = [[UIColor greenColor] CGColor];
      [self beepOrVibrate];
   }      
}

-(void) onDecode: (const unsigned short*) str: (const char*) strType
{
   NSString *qrcode = [NSString stringWithFormat:@"%S" , str];
	NSString *type  = [NSString stringWithFormat:@"%s" , strType];
   
   NSSet* set = [NSSet setWithObjects:qrcode, type, nil];
   
   // Shutdown Camera
	((CScanner*)m_pScanner)->CloseCamera();

   // Call delegate and callback
   [delegate overlayController:self returnResults:set];
}

-(void) OnCameraStopOrStart:(int) on  
{
	if (on == 1)
   {
      if (((CScanner*)m_pScanner)->IsTorchAvailable())
      {
      }
      [camera.view addSubview:self.view];
   }
	if (on == 0)
   {
      NSSet* set = [NSSet setWithObjects:@"", @"", nil];
      // Kill the view
      [delegate overlayController:self returnResults:set];
	}
}

-(void *) getScanner
{
   return m_pScanner;
}

-(int) getBTorch
{
   return m_bTorch;
}

-(void) setScanner:(void *)scanner  
{
   m_pScanner = scanner;
}

-(void) setBTorch:(int) on
{
   m_bTorch = on;
}

@end
