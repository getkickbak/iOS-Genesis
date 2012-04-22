/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2011, Nitobi Software Inc.
 * Copyright (c) 2011, Matt Kane
 * Copyright (c) 2011, IBM Corporation
 */

#import <Cordova/CDVFileTransfer.h>

@interface JFFileTransfer : CDVPlugin {
    
}
- (void) upload:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end


@interface JFFileTransferDelegate : NSObject {
	JFFileTransfer* command;
	NSString* callbackId;
    NSInteger bytesWritten;
    
}

@property (nonatomic, strong) NSMutableData* responseData;
@property (nonatomic, strong) JFFileTransfer* command;
@property (nonatomic, strong) NSString* callbackId;
@property NSInteger bytesWritten;


@end;