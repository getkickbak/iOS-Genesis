/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2011, Nitobi Software Inc.
 * Copyright (c) 2011, Matt Kane
 * Copyright (c) 2011, IBM Corporation
 */

#import "OverlayControllerNigma.h"
#import <Cordova/CDVPlugin.h>

enum QRCodeReaderError {
   CANCEL = 0,
	ERROR = 1,
   SUCCESS = 2
};

@interface QRCodeReaderNigma : CDVPlugin<OverlayControllerNigmaDelegate> {
   IBOutlet OverlayControllerNigma* overlayController;
   CameraViewController* cameraViewController;
	NSString* callbackId;
}
@property (strong) IBOutlet OverlayControllerNigma *overlayController;
@property (strong) CameraViewController *cameraViewController;
@property (nonatomic, strong) NSString* callbackId;
- (void) getCode:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end;