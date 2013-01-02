//
//  Receiver.h
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


#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>


@interface FastFT : NSObject {
	/**
	 * The audio sample rate. Most audio has a sample rate of 44.1kHz.
	 */
   float                sampleRate;
   int                  matchCount;
   
	int                  bufferLength;
	/**
	 * Fourier Transform object.
	 */
   FFTSetup            fftSetup;
   COMPLEX_SPLIT       split_data;
   /**
	 * Fourier Transform object.
	 */
	float               startFreq;
	/**
	 * Fourier Transform object.
	 */
	float               endFreq;
   /**
    * Threshold value before the declare it to be "valid signal".
    */
   int                 MAG_THRESHOLD;
}

-(int) getMagThreshold;
-(int) getErrorThreshold;
-(FastFT *) initFT :(float)audioSampleRate :(int)mCount :(int) length  :(int)magThreshold :(float)loFreq :(float)hiFreq;
-(NSMutableArray *) getPitch: (float*)buffer;

@end
