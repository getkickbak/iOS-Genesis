Instructions for pre-Cordova Projects (1.4.1 or older)
======================================================

    1. Download the latest CDVLocalStorage.h and CDVLocalStorage.m files from:

        a. https://raw.github.com/apache/incubator-cordova-ios/master/CordovaLib/Classes/CDVLocalStorage.h
        b. https://raw.github.com/apache/incubator-cordova-ios/master/CordovaLib/Classes/CDVLocalStorage.m

    2. Add the 2 files above to your project, under the "Plugins" group (make sure you add the files NOT as a folder reference!)

    3. Add the files from the "0.9.6_Compatibility" folder to your project, under the "Plugins" group (make sure you add the files NOT as a folder reference!)

    4. In your app's "AppDelegate.m", add the import:

        #import "CDVLocalStorage.h"

    5. In your app's "AppDelegate.m", add this to the top of your "application:didFinishLaunchingWithOptions" function:

	    [CDVLocalStorage __verifyAndFixDatabaseLocations];

    6. In your app's "AppDelegate.m", replace your "webViewDidStartLoad" function with this:

		- (void) webViewDidStartLoad:(UIWebView *)theWebView 
		{
		    static CDVLocalStorage* localStorage = nil;
		    if (localStorage == nil) {
		        localStorage = [[CDVLocalStorage alloc] initWithWebView:theWebView];   
		        [localStorage restore:nil withDict:nil];
		    }

			return [ super webViewDidStartLoad:theWebView ];
		}


    7. If you don't want to add add steps 4. and 5, you can control the backup, restore and verifyAndFixDatabaseLocations (iOS 5.1 app upgrade bug) from JavaScript. See the section below.


Calling the Plugin from JavaScript (1.4.1 or older)
===================================================

    1. In your PhoneGap.plist, under "Plugins", add a new row, with the string "CDVLocalStorage" as both key and value

    2. In your code, whenever you are ready, usually after the "deviceready" event has fired, you can then call this function:

        PhoneGap.exec(function(success){}, function(error){}, "CDVLocalStorage", "restore", []);

    3. Similarly, if you need to backup the localStorage at any time, you can call this function:
	
        PhoneGap.exec(function(success){}, function(error){}, "CDVLocalStorage", "backup", []);

    4. If you have security errors (due to a iOS 5.1 app upgrade bug):

        PhoneGap.exec(null, null, "CDVLocalStorage", "verifyAndFixDatabaseLocations", []);


Instructions for Cordova Projects (1.5.0 only)
======================================================

    1. Download the latest CDVLocalStorage.h and CDVLocalStorage.m files from:

        a. https://raw.github.com/apache/incubator-cordova-ios/master/CordovaLib/Classes/CDVLocalStorage.h
        b. https://raw.github.com/apache/incubator-cordova-ios/master/CordovaLib/Classes/CDVLocalStorage.m

    2. Add the 2 files above to your project, under the "Plugins" group (make sure you add the files NOT as a folder reference!)

    3. Add the files from the "1.5.0_Compatibility" folder to your project, under the "Plugins" group (make sure you add the files NOT as a folder reference!)

    4. In your app's "AppDelegate.m", add the import:

        #import "CDVLocalStorage.h"

    5. In your app's "AppDelegate.m", add this to the top of your "application:didFinishLaunchingWithOptions" function:

	    [CDVLocalStorage __verifyAndFixDatabaseLocations];
	
    6. In your app's "AppDelegate.m", replace your "webViewDidStartLoad" function with this:
	
		- (void) webViewDidStartLoad:(UIWebView*)theWebView
		{
		    static CDVLocalStorage* localStorage = nil;
		    if (localStorage == nil) {
		        localStorage = [[CDVLocalStorage alloc] initWithWebView:theWebView];   
		        [localStorage restore:nil withDict:nil];
		    }

			return [self.viewController webViewDidStartLoad:theWebView];
		}
	

    7. If you don't want to add add steps 4. and 5, you can control the backup, restore and verifyAndFixDatabaseLocations (iOS 5.1 app upgrade bug) from JavaScript. See the section below.


Calling the Plugin from JavaScript (1.5.0 only)
===================================================

    1. In your Cordova.plist, under "Plugins", add a new row, with the string "CDVLocalStorage" as both key and value

    2. In your code, whenever you are ready, usually after the "deviceready" event has fired, you can then call this function:

        Cordova.exec(function(success){}, function(error){}, "CDVLocalStorage", "restore", []);

    3. Similarly, if you need to backup the localStorage at any time, you can call this function:

        Cordova.exec(function(success){}, function(error){}, "CDVLocalStorage", "backup", []);

    4. If you have security errors (due to a iOS 5.1 app upgrade bug):

        Cordova.exec(null, null, "CDVLocalStorage", "verifyAndFixDatabaseLocations", []);
	