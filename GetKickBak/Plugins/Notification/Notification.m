/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "Notification.h"

@implementation Notification

- (void)showDialogWithMessage:(NSString*)message title:(NSString*)title buttons:(NSString*)buttons callbackId:(NSString*)callbackId
{
    AlertView* alertView = [[AlertView alloc]
            initWithTitle:title
                  message:message
                 delegate:self
        cancelButtonTitle:nil
        otherButtonTitles:nil];

    alertView.callbackId = callbackId;

    if (buttons != nil)
    {
      NSArray* labels = [buttons componentsSeparatedByString:@","];
      int count = [labels count];
      for (int n = 0; n < count; n++) {
        [alertView addButtonWithTitle:[labels objectAtIndex:n]];
      }
    }
    [alertView show];
   
   if (alertViews == nil) {
      alertViews = [[NSMutableDictionary alloc] init];
   }
   int key = arc4random() % 1000000 + 10000;
   alertView.key = key;
   [alertViews setValue:alertView forKey:[NSString stringWithFormat:@"%d", key]];
   
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:key];
   if (buttons == nil)
   {
      [self.commandDelegate sendPluginResult:result callbackId:alertView.callbackId];
   }
}

- (void)alert:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    int argc = [arguments count];

    NSString* message = argc > 0 ? [arguments objectAtIndex:0] : nil;
    NSString* title = argc > 1 ? [arguments objectAtIndex:1] : nil;
    NSString* buttons = argc > 2 ? [arguments objectAtIndex:2] : nil;

    if (!title) {
        title = NSLocalizedString(@"Alert", @"Alert");
    }
    if (!buttons) {
        buttons = NSLocalizedString(@"OK", @"OK");
    }

    [self showDialogWithMessage:message title:title buttons:buttons callbackId:callbackId];
}

- (void)confirm:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    int argc = [arguments count];

    NSString* message = argc > 0 ? [arguments objectAtIndex:0] : nil;
    NSString* title = argc > 1 ? [arguments objectAtIndex:1] : nil;
    NSString* buttons = argc > 2 ? [arguments objectAtIndex:2] : nil;

    if (!title) {
        title = NSLocalizedString(@"Confirm", @"Confirm");
    }
    if (!buttons) {
       //buttons = NSLocalizedString(@"OK,Cancel", @"OK,Cancel");
       [self showDialogWithMessage:message title:title buttons:nil callbackId:callbackId];
    }
    else {
       [self showDialogWithMessage:message title:title buttons:buttons callbackId:callbackId];       
    }

}

/**
 Callback invoked when an alert dialog's buttons are clicked.
 Passes the index + label back to JS
 */
- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    AlertView* cdvAlertView = (AlertView*)alertView;
    NSInteger key = [cdvAlertView key];
    [alertViews removeObjectForKey:[NSString stringWithFormat:@"%d", key]];
   
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:++buttonIndex];
    [self.commandDelegate sendPluginResult:result callbackId:cdvAlertView.callbackId];
}

- (void)vibrate:(CDVInvokedUrlCommand*)command
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)dismiss:(CDVInvokedUrlCommand*)command
{
   NSArray* arguments = command.arguments;
   int argc = [arguments count];
   
   int key = argc > 0 ? [[arguments objectAtIndex:0] intValue] : 0;
   //NSLog(@"alertView key[%d]", key);
   if (key > 0)
   {
      AlertView* cdvAlertView = (AlertView*)[alertViews valueForKey:[NSString stringWithFormat:@"%d", key]];
      [alertViews removeObjectForKey:[NSString stringWithFormat:@"%d", key]];
   
      int index = [cdvAlertView numberOfButtons];
      if (index > 0)
      {
         [cdvAlertView dismissWithClickedButtonIndex:index animated:TRUE];
      }
      else
      {
         [cdvAlertView dismissWithClickedButtonIndex:nil animated:TRUE];
      }
   }
}

@end

@implementation AlertView

@synthesize key;
@synthesize callbackId;

@end
