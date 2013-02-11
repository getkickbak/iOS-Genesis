//
//  GBDeviceInfo.h
//  GBDeviceInfo
//
//  Created by Luka Mirosevic on 11/10/2012.
//  Copyright (c) 2012 Luka Mirosevic.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.




#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface GBDeviceInfo : NSObject

//defs
typedef enum {
   GBDeviceModelUnknown = 0,
   GBDeviceModeliPhone,
   GBDeviceModeliPhone3G,
   GBDeviceModeliPhone3GS,
   GBDeviceModeliPhone4,
   GBDeviceModeliPhone4S,
   GBDeviceModeliPhone5,
   GBDeviceModeliPad,
   GBDeviceModeliPad2,
   GBDeviceModeliPad3,
   GBDeviceModeliPad4,
   GBDeviceModeliPadMini,
   GBDeviceModeliPod,
   GBDeviceModeliPod2,
   GBDeviceModeliPod3,
   GBDeviceModeliPod4,
   GBDeviceModeliPod5,
} GBDeviceModel;

typedef enum {
   GBDeviceFamilyUnknown = 0,
   GBDeviceFamilyiPhone,
   GBDeviceFamilyiPad,
   GBDeviceFamilyiPod,
} GBDeviceFamily;

typedef enum {
   GBDeviceDisplayUnknown = 0,
   GBDeviceDisplayiPad,
   GBDeviceDisplayiPhone35Inch,
   GBDeviceDisplayiPhone4Inch,
} GBDeviceDisplay;

typedef struct {
   GBDeviceModel           model;
   GBDeviceFamily          family;
   GBDeviceDisplay         display;
   NSUInteger              bigModel;
   NSUInteger              smallModel;
   NSUInteger              iOSVersion;
} GBDeviceDetails;

//public API
+(GBDeviceDetails)deviceDetails;
+(NSString *)rawSystemInfoString;

@end