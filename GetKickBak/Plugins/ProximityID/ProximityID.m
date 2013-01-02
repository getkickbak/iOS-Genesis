//
//  ProximityID.m
//  ProximityID
//
//  Created by Eric Chan on 12/12/12.
//
// THIS SOFTWARE IS PROVIDED BY ERIC CHAN "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
// EVENT SHALL ERIC CHAN OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <MediaPlayer/MPMusicPlayerController.h>
#import "ProximityID.h"
#import "Sender.h"
#import "Receiver.h"

#define TAG                         @"ProximityID - "

static int                          ILLEGAL_ACCESS_ERROR = 1;

/*
NSString* ERROR_NOT_FOUND =         @"file not found";
NSString* WARN_EXISTING_REFERENCE = @"a reference to the audio ID already exists";
NSString* ERROR_MISSING_REFERENCE = @"a reference to the audio ID does not exist";
NSString* CONTENT_LOAD_REQUESTED =  @"content has been requested";
NSString* PLAY_REQUESTED =          @"PLAY REQUESTED";
NSString* STOP_REQUESTED =          @"STOP REQUESTED";
NSString* UNLOAD_REQUESTED =        @"UNLOAD REQUESTED";
NSString* RESTRICTED =              @"ACTION RESTRICTED FOR FX AUDIO";
*/

@interface ProximityID()
- (void) receiverResume;
@end

@implementation ProximityID

- (void) preLoadIdentity:(CDVInvokedUrlCommand*)command
{
   CDVPluginResult* pluginResult;
   [sender preLoad];
   pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:
                   [[NSDictionary alloc] initWithObjectsAndKeys:nil]];
   [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) sendIdentity:(CDVInvokedUrlCommand*)command
{
   CDVPluginResult* pluginResult;

   //
   // Already underway ...
   //
   if (![sender isStopped])
   {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:
       [[NSDictionary alloc] initWithObjectsAndKeys:nil]];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
      return;
   }
   
   //and whereever you want to play the sound, call the lines below
   s_vol=[MPMusicPlayerController applicationMusicPlayer].volume; //grab current User volume
   [[MPMusicPlayerController applicationMusicPlayer] setVolume:s_vol_ratio];//set system vol to max
   NSLog(TAG @"sendIdentity - Setting Volume to [%f]", s_vol_ratio);

   // Check command.arguments here.
   NSMutableArray *freqs = [sender process];
   //NSLog(TAG @"Setting Freqs to [%@]", freqs);
   pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:
   [[NSDictionary alloc] initWithObjectsAndKeys:freqs,@"freqs",nil]];
   // The sendPluginResult method is thread-safe.
   [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) scanIdentityCallback :(NSMutableArray*)freqs :(NSString*)callbackId
{   
   CDVPluginResult* pluginResult;
   if (freqs != nil)
   {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:
      [[NSDictionary alloc] initWithObjectsAndKeys:freqs,@"freqs",nil]];
   }
   else
   {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageToErrorObject:-1];
   }
   
   // The sendPluginResult method is thread-safe.
   [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];   
}

- (void) scanIdentity:(CDVInvokedUrlCommand*)command
{
   CDVPluginResult* pluginResult;
   
   if (receiver != nil)
   {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ILLEGAL_ACCESS_EXCEPTION messageAsDictionary:
      [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:ILLEGAL_ACCESS_ERROR],@"code",nil]];
      // The sendPluginResult method is thread-safe.
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
      return;
   }
   
   int samples = [[command.arguments objectAtIndex:0] intValue];
   int missedThreshold = [[command.arguments objectAtIndex:1] intValue];
   int magThreshold = [[command.arguments objectAtIndex:2] intValue];
   double overlapRatio = [[command.arguments objectAtIndex:3] doubleValue];
   
   s_vol=[MPMusicPlayerController applicationMusicPlayer].volume; //grab current User volume
   [[MPMusicPlayerController applicationMusicPlayer] setVolume:r_vol_ratio];//set system vol to max
   NSLog(TAG @"scanIdentity - Setting Volume to [%f]", r_vol_ratio);

   //
   // Cannot override initial setttings
   //
   //if (receiver == nil)
   {
      receiver = [[Receiver alloc] initRecv :samples :missedThreshold :magThreshold :overlapRatio];
   }
   
   // Check command.arguments here.
   [self.commandDelegate runInBackground:^{
      NSLog(TAG @"CallbackId - [%@]", command.callbackId);
     [receiver process :self :command.callbackId];
   }];
}

- (void)onReset
{
   [self stop :nil];
}

- (void)onAppTerminate
{
   [sender release];
   if (receiver != nil)
   {
      [receiver release];
   }
}

- (void) init:(CDVInvokedUrlCommand*)command
{
   CDVPluginResult* pluginResult = nil;
   s_vol_ratio = [[command.arguments objectAtIndex:0] floatValue];
   r_vol_ratio = [[command.arguments objectAtIndex:1] floatValue];
   sender = [[Sender alloc] init];
   receiver = nil;
   s_vol = -1;
   
   pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
   [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) receiverResume
{
   NSLog(TAG @"resume");
   [receiver resume];
}

- (void) restart :(Boolean)isSender
{
   // No need to implement Sender restart ...
   if (isSender)
   {
   }
   else
   {
      /*
      [self.commandDelegate runInBackground:^{
         int samples = [receiver getFrameCount];
         int missedThreshold = [receiver getConseqMissedThreshold];
         double overlapRatio = [receiver getOverlapRatio];
         NSString *callbackId = [receiver getCallbackId];
         [receiver release];
         receiver = [[Receiver alloc] initRecv :samples :missedThreshold :magThreshold :overlapRatio];
         [receiver process :self :callbackId];
      }];
      */
   }
}

- (void) stop:(CDVInvokedUrlCommand*)command
{
   [sender stop];
   if (receiver != nil)
   {
      [receiver release];
      receiver = nil;
   }
   
   //
   // Restore original volume, ready to take on more tasks
   //
   if (s_vol > 0)
   {
      [[MPMusicPlayerController applicationMusicPlayer]setVolume:s_vol];//returns volume to original setting
      NSLog(TAG @"Setting Volume Back to [%f]", s_vol);
      s_vol = -1;
   }
   if (command != nil)
   {
      CDVPluginResult* pluginResult = nil;
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
   }
}

- (void) setVolume:(CDVInvokedUrlCommand*)command
{
   CDVPluginResult* pluginResult = nil;
   float volume = [[command.arguments objectAtIndex:0] intValue];
   if (volume < 0)
   {
      volume = s_vol;
   }
   else
   {
      volume /= 100.0;
   }
   
   [[MPMusicPlayerController applicationMusicPlayer] setVolume:volume];//set system vol to max
   NSLog(TAG @"Setting Volume to [%f]", volume);
   
   pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
   [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
