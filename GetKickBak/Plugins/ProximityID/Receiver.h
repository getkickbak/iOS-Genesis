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
#import <AudioToolbox/AudioToolbox.h>
#import <Communicator.h>
#import <FastFT.h>
#import <ProximityID.h>


@interface Receiver : Communicator
{
   //
   // Threshold value before the declare it to be "valid signal".
   //
   int                           MAG_THRESHOLD;
   //
   // Grab data fresh from audioInput if we cannot find a signal lock
   //
   int                           CONSEQ_MISSED_THRESHOLD;
   //
   // Data overlap for each FFT calculation
   //
   double                        OVERLAP_RATIO;
	//
	// AudioData buffer used for FFT
	//
	AUGraph                       processingGraph;
   AudioStreamBasicDescription   audioFormat;
	AudioComponentInstance        audioUnit;
   AudioBufferList               bufferList; // This buffers incoming data from microphone
	AudioBuffer                   audioData; // This buffer holds 2*N Samples
   int                           inputIndex;
   Boolean                       readyToRecv;

	//
	// AudioData buffer used to read from Speakers
   // Internal variables used to keep track of where we are in the audioBuffer
   //
	float*                        fftBuf;   
   int                           overlapIteration;
   int                           overlapOffset; // Increment by OVERLAP_RATIO*N
   int                           matchCount;
   int                           conseqMissedCounts;
	//
	// FFT instantiation
	//
	FastFT*                       alg;

   ProximityID*                  application;
   NSString*                     callbackId;
}

-(id)initRecv :(int)samples :(int)missedThreshold :(int)magThreshold :(double)overlapRatio;
-(int)getMatchCountThreshold;
-(int)getConseqMissedThreshold;
-(double)getOverlapRatio;
-(NSString *)getCallbackId;
-(int)getMaxFrameSize;
-(void)preProcessAudio :(int)inNumberFrames;
-(void)process :(ProximityID *)app :(NSString*)cbId;
-(void)cleanup;
-(void)pause;
-(void)resume;
-(void)stop;

@property Boolean readyToRecv;
@property (readonly) AudioComponentInstance audioUnit;
@property (readonly) AudioStreamBasicDescription audioFormat;
@property AudioBufferList bufferList;

@end

// setup a global receiver variable, accessible everywhere
extern Receiver* receiver;

