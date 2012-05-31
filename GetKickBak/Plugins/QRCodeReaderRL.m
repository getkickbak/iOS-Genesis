/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2011, Nitobi Software Inc.
 * Copyright (c) 2011, Matt Kane
 * Copyright (c) 2011, IBM Corporation
 */

#import "QRCodeReaderRL.h"


@implementation QRCodeReaderRL

@synthesize callbackId;
@synthesize pickerController;
@synthesize overlayController;

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
   	
   NSLog(@"Initializing Scanner ....");
	// hide the status bar
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
   
   pickerController = [[BarcodePickerController alloc] init];
   //overlayController = [[OverlayControllerRL alloc] initWithNibName:@"ScanOverlayRL" bundle:nil];
   overlayController = [[OverlayControllerRL alloc] initWithNibName:@"ScanOverlayNigma" bundle:nil];
   [pickerController setOverlay:overlayController];
   [pickerController setDelegate:self];
   
   // Initialize with portrait mode as default
   pickerController.orientation = UIImageOrientationUp;
   
   // The active scanning region size is set in OverlayController.m
	
	// Update barcode on/off settings
	[pickerController setScanQRCODE:YES];
	
	// Data matrix decoding does not work very well so it is disabled for now
	[pickerController setScanDATAMATRIX:NO];
   
    // Show the scanner view
    [[super viewController] presentModalViewController:pickerController animated:TRUE];   
   NSLog(@"Loaded Scanner ....");
}

- (void) barcodePickerController:(BarcodePickerController*)picker returnResults:(NSSet *)results
{	
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
	
	// Restore main screen (and restore title bar for 3.0)
	[[super viewController] dismissModalViewControllerAnimated:TRUE];
	
	// Note that it is possible to get multiple results discovered at the same time.
	// Even if you return as soon as you see result barcodes, there could be more than one.
	BarcodeResult *foundCode = [results anyObject];
	if (foundCode)
   {
		NSString *barcodeTextLabel = foundCode.barcodeString;
      NSString *typeLabel;
      
		int btype = foundCode.barcodeType;
		if (btype == kBarcodeTypeEAN13) 
         { 
            // Use first digit to differentiate between EAN13 and UPCA
            // An EAN13 barcode whose first digit is zero is exactly the same as a UPCA barcode.
            if ([foundCode.barcodeString characterAtIndex:0] == '0') 
               {
               barcodeTextLabel = [foundCode.barcodeString substringFromIndex:1];
               typeLabel = @"UPC-A";
               }
            else
               {
               typeLabel = @"EAN-13";
               }			
         }
		else if (btype == kBarcodeTypeEAN8) typeLabel = @"EAN-8";
		else if (btype == kBarcodeTypeUPCE) typeLabel = @"UPC-E";
		else if (btype == kBarcodeTypeQRCODE) typeLabel = @"QR Code";
		else if (btype == kBarcodeTypeCODE128) typeLabel = @"Code 128";
		else if (btype == kBarcodeTypeCODE39) typeLabel = @"Code 39";
		else if (btype == kBarcodeTypeDATAMATRIX) typeLabel = @"Data Matrix";
		else if (btype == kBarcodeTypeITF) typeLabel = @"ITF";
		else if (btype == kBarcodeTypeSTICKY) typeLabel = @"STICKYBITS";
		
   }
   // create dictionary to return FileUploadResult object
   NSMutableDictionary* uploadResult = [NSMutableDictionary dictionaryWithCapacity:1];
   if (foundCode.barcodeString && foundCode.barcodeType)
   {
      [uploadResult setObject:foundCode.barcodeString forKey: @"response"];
   }
   CDVPluginResult* result = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDictionary: uploadResult cast: @"window.plugins.qrCodeReader._didFinishWithResult"];
   [self writeJavascript:[result toSuccessCallbackString: callbackId]];
}

@end

