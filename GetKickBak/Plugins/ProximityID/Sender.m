//
//  Sender.m
//  ProximityID
//
//  Created by Eric Chan on 12/10/12.
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

#import "GBDeviceInfo.h"
#import "Sender.h"
#import <AVFoundation/AVAudioPlayer.h>

#define TAG               @"ProximityID-Sender - "

static const int    DURATION  = 1;                                       // seconds
static const double AMPLITUDE = 1.0;

Sender  *sender;

static void checkStatus(int status)
{
	if (status)
   {
		NSLog(TAG @"Status not 0! %d\n", status);
      //		exit(1);
   }
}

@interface Sender()
-(void) genTone;
@end

@implementation Sender

-(void) genTone
{
   // Convert the floating point audio data into signed 16-bit.
   SInt16* payload = (SInt16*)(wavBuffer + 44);
   for (int i = 0; i < numSamples; ++i)
   {
      double val = 0.0;
      // convert to 16 bit pcm sound array
      // assumes the sample buffer is normalised.
      for (int j = 0; j < [super getNumSignals]; j++)
      {
         val += sin(2 * M_PI * [[freqs objectAtIndex:j] intValue] * i / [super getSampleRate]);
      }
      val /= ([super getNumSignals] / AMPLITUDE);
      payload[i] = (SInt16) (val * SHRT_MAX);
   }
}

-(id) init
{
   self = [super init];
   freqs = [[NSMutableArray alloc] initWithObjects:nil];
   abort = paused = false;
   numSamples = DURATION * [super getSampleRate];
   audioPlayer = nil;
   
   // AVAudioPlayer will only play formats it knows. It cannot play raw
   // audio data, so we will convert the raw floating point values into
   // a 16-bit WAV file.
   
   unsigned int payloadSize = numSamples*sizeof(SInt16);  // byte size of waveform data
   unsigned int wavSize = 44 + payloadSize;           // total byte size
   
   // Allocate a memory buffer that will hold the WAV header and the
   // waveform bytes.
   wavBuffer = (SInt8*)malloc(wavSize);
   if (wavBuffer == nil)
   {
      NSLog(TAG @"Error allocating %u bytes", wavSize);
      [self release];
      return nil;
   }
   
   // Fake a WAV header.
   SInt8* header = wavBuffer;
   header[0x00] = 'R';
   header[0x01] = 'I';
   header[0x02] = 'F';
   header[0x03] = 'F';
   header[0x08] = 'W';
   header[0x09] = 'A';
   header[0x0A] = 'V';
   header[0x0B] = 'E';
   header[0x0C] = 'f';
   header[0x0D] = 'm';
   header[0x0E] = 't';
   header[0x0F] = ' ';
   header[0x10] = 16;    // size of format chunk (always 16)
   header[0x11] = 0;
   header[0x12] = 0;
   header[0x13] = 0;
   header[0x14] = 1;     // 1 = PCM format
   header[0x15] = 0;
   header[0x16] = 1;     // number of channels
   header[0x17] = 0;
   header[0x18] = 0x44;  // samples per sec (44100)
   header[0x19] = 0xAC;
   header[0x1A] = 0;
   header[0x1B] = 0;
   header[0x1C] = 0x88;  // bytes per sec (88200)
   header[0x1D] = 0x58;
   header[0x1E] = 0x01;
   header[0x1F] = 0;
   header[0x20] = 2;     // block align (bytes per sample)
   header[0x21] = 0;
   header[0x22] = 16;    // bits per sample
   header[0x23] = 0;
   header[0x24] = 'd';
   header[0x25] = 'a';
   header[0x26] = 't';
   header[0x27] = 'a';
   
   *((SInt32*)(wavBuffer + 0x04)) = payloadSize + 36;   // total chunk size
   *((SInt32*)(wavBuffer + 0x28)) = payloadSize;        // size of waveform data
	
   return self;
}

-(int) getDuration
{
   return DURATION;
}

-(int) getNumSamples
{
   return numSamples;
}

-(void) preLoad
{
   //
   // Distribute frequencies to appropriate sections
   //
   double bw = [self getBandwidth] / [super getNumSignals];
   int sigs[[super getNumSignals]];
   Boolean stay = false;
   GBDeviceDetails deviceDetails = [GBDeviceInfo deviceDetails];
   do
   {
      stay = false;
      for (int i = 0; i <[super getNumSignals] - 1; i++)
      {
         sigs[i] = arc4random_uniform(bw) + i*bw + [super getStartFreq];
      }
      if (deviceDetails.family == GBDeviceFamilyiPod)
      {
         sigs[[super getNumSignals] - 1] = arc4random_uniform(bw/2 - 8) + (([super getNumSignals] - 1) * bw) + [super getStartFreq];
      }
      else
      {
         sigs[[super getNumSignals] - 1] = arc4random_uniform(bw/2) + (([super getNumSignals] - 1) * bw) + [super getStartFreq];
      }
   
      for (int i = 0; i < ([super getNumSignals] - 1); i++)
      {
         if ((sigs[i] + [super getFreqGap]) > sigs[i+1])
         {
            stay = true;
            break;
         }
      }
   } while (stay);
   [freqs removeAllObjects];
   for (int i = 0; i < [super getNumSignals]; i++)
      {
      [freqs addObject: [NSNumber numberWithInt:sigs[i]]];
      }
   //NSLog(TAG @"BW[%.1f] Freqs \n%@", bw, freqs);
   
   [self cleanup];
   
   unsigned int payloadSize = numSamples*sizeof(SInt16);  // byte size of waveform data
   unsigned int wavSize = 44 + payloadSize;           // total byte size
   
   [self genTone];
   
   
   // Put everything in an NSData object.
   NSData* data = [[NSData alloc] initWithBytesNoCopy:wavBuffer length:wavSize];

   [self stop];
   // Create the AVAudioPlayer.
   NSError* error = nil;
   audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
   [audioPlayer retain];
   [audioPlayer prepareToPlay];
   [data release];
   
   if (error != nil)
   {
      NSLog(TAG @"%@", error);
      return;
   }
   
   if (deviceDetails.family == GBDeviceFamilyiPod)
   {
      for (int i = 0; i < [super getNumSignals]; i++)
      {
         NSNumber *freq = [freqs objectAtIndex:i];
         [freqs replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:[freq integerValue] + 8]];
      }
   }
}

-(NSMutableArray*)process
{
   audioPlayer.volume = 1.0;
   audioPlayer.numberOfLoops = -1;
	[audioPlayer play];
   stopped = false;
   
   NSLog(TAG @"Generating Tones ... \n%@", freqs);
   
   return freqs;
}

- (void)pause
{
   if (audioPlayer != nil)
   {
      [audioPlayer pause];
      paused = true;
      NSLog(TAG @"Paused AudioTrack playback ...");
   }
   stopped = false;
}

- (void)resume
{
   if (audioPlayer != nil)
   {
      [audioPlayer play];
      paused = false;
      NSLog(TAG @"Resumed AudioTrack playback ...");
   }
   stopped = false;
}

- (void)stop
{
   if (audioPlayer != nil)
   {
      paused = false;
      [audioPlayer stop];
      [audioPlayer release];
      NSLog(TAG @"Stopped AudioTrack playback ...");
      audioPlayer = nil;
   }
   stopped = true;
}

- (void)cleanup
{
   [self stop];
}

- (void)dealloc
{
   [self cleanup];
   free(wavBuffer);
   [freqs release];
   wavBuffer = nil;
   freqs = nil;
	[super dealloc];
}

@end
