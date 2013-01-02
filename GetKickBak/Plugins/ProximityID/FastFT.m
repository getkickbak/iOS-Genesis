//
//  FastFT.m
//  ProximityID
//
//  Created by Eric Chan on 12/11/12.
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

#import "FastFT.h"

#define TAG                     @"ProximityID-FastFT - "

/**
 * VALUE is 4x the size of Android code because we are doubling the sample size to compensate for FFT matrix size and
 * the matrix is twice the size of comparable size in Android because we have it mixed in with Real/Imaginary arrays together
 */
static int ERROR_THRESHOLD     = 175*2*2;
/**
 * The expected size of an audio buffer (in samples).
 */
static int DEFAULT_BUFFER_SIZE = 1024;

/**
 * Overlap defines how much two audio buffers following each other should
 * overlap (in samples). 75% overlap is advised in the MPM article.
 */
static int DEFAULT_OVERLAP     = 768;

static float MagnitudeSquared(float x, float y)
{
	return ((x*x) + (y*y));
}

@implementation FastFT

-(int) getMagThreshold
{
   return MAG_THRESHOLD;
}

-(int) getErrorThreshold
{
   return ERROR_THRESHOLD;
}

-(id) initFT : (float)audioSampleRate : (int) mCount :(int) length  : (int)magThreshold :(float)loFreq : (float)hiFreq
{
   [super init];
   
   MAG_THRESHOLD = magThreshold;
   matchCount = mCount;
   sampleRate = audioSampleRate;
   startFreq = loFreq;
   endFreq = hiFreq;
   bufferLength = length;
   
   size_t fftSize = bufferLength; // sample size
   size_t log2n = log2f(fftSize); // bins
   
   split_data.realp = (float *) malloc(fftSize/2 * sizeof(float));
   split_data.imagp = (float *) malloc(fftSize/2 * sizeof(float));
   //NSLog(TAG @"split_data size=%zu", fftSize/2);

   // allocate the fft object once
   fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
   if (fftSetup == NULL) {
      NSLog(TAG @"FFT_Setup failed to allocate enough memory.\n");
   }
   //NSLog(TAG @"FFT_Setup sampleRate[%.1f], startFreq[%.1f], endFreq[%.1f], fftSize[%lu]", sampleRate, startFreq, endFreq, fftSize);
   
   return self;
}

-(NSMutableArray *) getPitch: (float*)buffer
{
   NSMutableArray *ret = nil;
   NSMutableArray *maxMag = [NSMutableArray arrayWithObjects: nil];
   //memccpy(buffer, audioBuffer, bufferLength/2, sizeof(float));
   
   size_t fftSize = bufferLength; // sample size
   size_t log2n = log2f(fftSize); // bins
   
   //NSLog(TAG @"fftSize=%zu", fftSize);
   /**
    Look at the real signal as an interleaved complex vector by casting it.
    Then call the transformation function vDSP_ctoz to get a split complex
    vector, which for a real signal, divides into an even-odd configuration.
    */
   //convert to split complex format with evens in real and odds in imag
   vDSP_ctoz((COMPLEX *) buffer, 2, &split_data, 1, fftSize/2);
   
   //calc fft
   vDSP_fft_zrip(fftSetup, &split_data, 1, log2n, FFT_FORWARD);

   //convert complex split to real
   vDSP_ztoc(&split_data, 1, (COMPLEX*)buffer, 2, fftSize/2);
   
   // Normalize
   //float scale = 1.f/fftSize;
   //vDSP_vsmul(buffer, 1, &scale, buffer, 1, fftSize);

   int start = (lroundf(startFreq / (sampleRate / bufferLength)) - 1)*2;
   int end = (lroundf(endFreq / (sampleRate / bufferLength)) + 1)*2;
      
   // Determine the dominant frequency by taking the magnitude squared and
   // saving the bin which it resides in.
   //NSLog(TAG @"startIndex=[%d], endIndex=[%d]", start, end);
   for (int i=start; i < end; i+=2)
   {
      //compute magnitude
      int mag = sqrtf(MagnitudeSquared(buffer[i], buffer[i+1]));
      if (mag < MAG_THRESHOLD){continue;}
      //NSLog(TAG @"mag=[%d] freq=[%.1f]", mag, i * ((sampleRate/2) / bufferLength));
      
      //
      // Sort on Freq Index (asc)
      //
      [maxMag sortUsingComparator:^(id obj1, id obj2)
      {
         int value1 = [[obj1 objectAtIndex: 1] intValue];
         int value2 = [[obj2 objectAtIndex: 1] intValue];
         //NSLog(TAG @"sortUsingComparator - value1=[%d], value2=[%d]", value1, value2);
         if (value1 > value2)
         {
         return (NSComparisonResult)NSOrderedDescending;
         }
         if (value1 < value2)
         {
            return (NSComparisonResult)NSOrderedAscending;
         }
         return (NSComparisonResult)NSOrderedSame;
      }];
      //
      // Find any nearby Index with similar Frequency
      //
      //NSLog(TAG @"maxMag Count=[%d]", [maxMag count]);
      int foundIndex = [maxMag indexOfObject:[NSNumber numberWithInteger:i]
                              inSortedRange:NSMakeRange(0, [maxMag count])
                                 options:NSBinarySearchingFirstEqual
                             usingComparator:^(id obj1, id obj2)
      {
         int value1 = [[obj1 objectAtIndex: 1] intValue];
         int value2 = [obj2 intValue];
                     
         //NSLog(TAG @"indexOfObject - value1=[%d], value2=[%d]", value1, value2);
         Boolean isNeighbor = imaxabs(value1 - value2) <= ERROR_THRESHOLD;
         if (isNeighbor) { return (NSComparisonResult)NSOrderedSame; }
         if (value1 < value2)
         {
            return (NSComparisonResult)NSOrderedAscending;
         }
         if (value1 > value2)
         {
            return (NSComparisonResult)NSOrderedDescending;
         }
         return (NSComparisonResult)NSOrderedSame;
      }];
      
      NSMutableArray *obj;
      //NSLog(TAG @"foundIndex=[%d]", foundIndex);
      if (foundIndex != NSNotFound)
      {
         NSMutableArray *tmp = [maxMag objectAtIndex: foundIndex];
         int tmpMag = [[tmp objectAtIndex: 0] intValue];
         //int tmpIndex = [[tmp objectAtIndex: 1] intValue];
         //
         // Found an existing power even larger than adjacent power values
         //
         if (tmpMag < mag)
         {
            obj = [NSMutableArray arrayWithObjects: [NSNumber numberWithInteger:mag], [NSNumber numberWithInteger:i], nil];
            [maxMag setObject : obj atIndexedSubscript : foundIndex];
            //NSLog(TAG @"Index[%d] Update Index Freq Found= %.1fHz, Magitutde= %d, start[%d], end[%d]", i, i * ((sampleRate/2) / bufferLength), mag, start, end);
         }
      }
      else
      {
         obj = [NSMutableArray arrayWithObjects: [NSNumber numberWithInteger:mag], [NSNumber numberWithInteger:i], nil];
         [maxMag addObject : obj];
         //NSLog(TAG @"Add Index Freq Found= %fHz, Magitutde= %d", i * ((sampleRate/2) / bufferLength), mag);
      }
   }
   if ([maxMag count] >= matchCount)
   {
      //
      // Sort on Magnitude (desc)
      //
      [maxMag sortUsingComparator:^(id obj1, id obj2)
      {
         NSInteger value1 = [[obj1 objectAtIndex: 1] intValue];
         NSInteger value2 = [[obj2 objectAtIndex: 1] intValue];
         if (value2 > value1)
         {
            return (NSComparisonResult)NSOrderedDescending;
         }
         if (value2 < value1)
         {
            return (NSComparisonResult)NSOrderedAscending;
         }
         return (NSComparisonResult)NSOrderedSame;
      }];
      //
      // Get to Top "matchCount" results
      //
      ret = [NSMutableArray arrayWithObjects: nil];
      for (int i = 0; i < matchCount; i++)
      {
         int freq = [[[maxMag objectAtIndex: i] objectAtIndex : 1] intValue];
         NSNumber  *f = [NSNumber numberWithInteger : lroundf(freq * ((sampleRate/2) / bufferLength))];
         [ret insertObject:f atIndex : i];
      }
      //
      // Sort on Frequency (asc)
      //
      [ret sortUsingComparator:^(id obj1, id obj2)
      {
         NSInteger value1 = [obj1 intValue];
         NSInteger value2 = [obj2 intValue];
         if (value1 > value2)
         {
            return (NSComparisonResult)NSOrderedDescending;
         }
         if (value1 < value2)
         {
            return (NSComparisonResult)NSOrderedAscending;
         }
         return (NSComparisonResult)NSOrderedSame;
      }];
   }
   [maxMag release];
   
   return ret;
}

- (void)dealloc
{
   free(split_data.imagp);
   free(split_data.realp);
   vDSP_destroy_fftsetup(fftSetup);
   [super dealloc];
}

@end
