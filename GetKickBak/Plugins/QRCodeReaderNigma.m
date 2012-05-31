/*
 * Cordova is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2011, Nitobi Software Inc.
 * Copyright (c) 2011, Matt Kane
 * Copyright (c) 2011, IBM Corporation
 */

#import "QRCodeReaderNigma.h"


@implementation QRCodeReaderNigma

@synthesize callbackId;
@synthesize overlayController;
@synthesize cameraViewController;

- (void) getCode:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
   callbackId = [arguments objectAtIndex:0];
   enum QRCodeReaderError result = CANCEL;
   int errorCode;
   
   switch (result)
   {
      case CANCEL:
      errorCode = 0;
      break;
      case ERROR:
      errorCode = 1;
      break;
      case SUCCESS:
      errorCode =2;
      break;
   }
   
   if(errorCode > 0) {
   	NSString* jsString = [[NSString alloc] initWithFormat:@"window.plugins.qrCodeReader._didNotFinishWithResult(%d);",errorCode];
      [self writeJavascript:jsString];
      [jsString release];
      return;
   }
      
   NSLog(@"Initializing Scanner ...");
	// hide the status bar
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
   
   cameraViewController = [[CameraViewController alloc] init];
   overlayController = [[OverlayControllerNigma alloc] initWithNibName:@"ScanOverlayNigma" bundle:nil];
   [cameraViewController setOverlay:overlayController];
   [overlayController setDelegate:self];
   [overlayController setCamera:cameraViewController];
	
   // Show the scanner view
   [[super viewController] presentModalViewController:cameraViewController animated:TRUE];   
}

- (void) overlayController:(OverlayControllerNigma*)overlay returnResults:(NSSet *)results
{	
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
	
	// Restore main screen (and restore title bar for 3.0)
	[[super viewController] dismissModalViewControllerAnimated:TRUE];

   // create dictionary to return FileUploadResult object
   NSMutableDictionary* uploadResult = [NSMutableDictionary dictionaryWithCapacity:1];
   NSArray *items = [results allObjects];
   NSString *qrcode = [items objectAtIndex:0];
   NSString *type = [items objectAtIndex:1];
   if (qrcode && type)
   {
      [uploadResult setObject:qrcode forKey: @"response"];
   }
   CDVPluginResult* result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDictionary: uploadResult cast: @"window.plugins.qrCodeReader._didFinishWithResult"];
   
   [self writeJavascript:[result toSuccessCallbackString: callbackId]];
}

@end

