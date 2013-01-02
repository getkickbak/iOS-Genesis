//
//  Receiver.m
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

#import "Receiver.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

static int          MATCH_THRESHOLD       = 1;
static int          MAX_FRAMES_SIZE       = 16*1024;
static int          SYS_BUFFER_SIZE       = 1024;
static int          SAMPLE_BUFFER_RATIO   = 4;

#define kOutputBus                       0
#define kInputBus                        1
#define TAG                              @"ProximityID-Receiver - "

Receiver* receiver;

static void checkStatus(int status)
{
	if (status)
   {
		NSLog(TAG "Status not 0! %d\n", status);
	}
}

static void checkNSError(NSError *error)
{
	if (error != nil)
   {
		NSLog(TAG "Status Error! Code = %d\n", error.code);
   }
}

/**
 This callback is called when new audio data from the microphone is
 available.
 */
static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData)
{
   OSStatus status;
   Receiver *recv = (Receiver *)inRefCon;
   AudioBufferList bufferList = [recv bufferList];
	
   status = AudioUnitRender([recv audioUnit],
                            ioActionFlags,
                            inTimeStamp,
                            inBusNumber,
                            inNumberFrames,
                            &bufferList);
	checkStatus(status);
   if (status < 0)
   {
		return status;
	}
   
   // Now, we have the samples we just read sitting in buffers in bufferList
   // Process the new data
   [recv preProcessAudio :inNumberFrames];
   return noErr;
}

@interface Receiver()

-(void)createAUProcessingGraph;
-(size_t)ASBDForSoundMode;
-(void)processAudio :(NSMutableArray *)sigFreq;
-(void)start;
-(void)printASBD :(AudioStreamBasicDescription)asbd;

@end

@implementation Receiver

@synthesize audioUnit, audioFormat, bufferList, readyToRecv;

-(id) initRecv :(int)samples :(int)missedThreshold :(int)magThreshold :(double)overlapRatio
{
   self = [super init];
   N = samples;

   CONSEQ_MISSED_THRESHOLD = missedThreshold;
   MAG_THRESHOLD = magThreshold;
   OVERLAP_RATIO = overlapRatio;
   
   [self setReadyToRecv :true];
   
   NSError	*err = nil;
	AVAudioSession *session = [AVAudioSession sharedInstance];
   
	[session setPreferredSampleRate: [super getSampleRate] error:&err];
   checkNSError(err);
	[session setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
   checkNSError(err);
   //
   // This is a MUST to make sure that Automatic Gain Adjustments
   // were made to the signal to get precise signal data
   //
   [session setMode:AVAudioSessionModeMeasurement error:&err];
   checkNSError(err);
	[session setActive:YES error:&err];
   checkNSError(err);
   
   [self createAUProcessingGraph];
   
   return(self);
}

- (void)createAUProcessingGraph
{
   //
   // Initialize AudioGraph
   //
   OSStatus status;
   overlapOffset = overlapIteration = 0;
	NewAUGraph(&processingGraph);
	// Describe audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	AUNode ioNode;
	status = AUGraphAddNode(processingGraph, &desc, &ioNode);
   checkStatus(status);
   status = AUGraphOpen(processingGraph); // indirectly performs audio unit instantiation
   checkStatus(status);
	// Obtain a reference to the newly-instantiated I/O unit. Each Audio Unit
	// requires its own configuration.
	status = AUGraphNodeInfo(processingGraph, ioNode, NULL, &audioUnit);
   checkStatus(status);
   
	// Enable IO for recording
	UInt32 flag = 1;
	status = AudioUnitSetProperty(audioUnit,
                                 kAudioOutputUnitProperty_EnableIO,
                                 kAudioUnitScope_Input,
                                 kInputBus,
                                 &flag,
                                 sizeof(flag));
	checkStatus(status);
   
	size_t bytesPerSample = [self ASBDForSoundMode];
	
	// Apply format
	status = AudioUnitSetProperty(audioUnit,
                                 kAudioUnitProperty_StreamFormat,
                                 kAudioUnitScope_Output,
                                 kInputBus,
                                 &audioFormat,
                                 sizeof(audioFormat));
	checkStatus(status);
   
	// Set input callback
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = recordingCallback;
	callbackStruct.inputProcRefCon = self;
	status = AudioUnitSetProperty(audioUnit,
                                 kAudioOutputUnitProperty_SetInputCallback,
                                 kAudioUnitScope_Global,
                                 kInputBus,
                                 &callbackStruct,
                                 sizeof(callbackStruct));
	checkStatus(status);
   
	// Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
	flag = 0;
	status = AudioUnitSetProperty(audioUnit,
                                 kAudioUnitProperty_ShouldAllocateBuffer,
                                 kAudioUnitScope_Output,
                                 kInputBus,
                                 &flag,
                                 sizeof(flag));
	
	// Allocate our own buffers (1 channel, 16 bits per sample, thus 16 bits per frame, thus 2 bytes per frame).
	// Practice learns the buffers used contain N frames, if this changes it will be fixed in preProcessAudio.
	audioData.mNumberChannels = 1;
	audioData.mDataByteSize = (int)(SAMPLE_BUFFER_RATIO*N)*bytesPerSample;
	audioData.mData = malloc(audioData.mDataByteSize);
   
	// Allocate AudioBuffers for use when listening.
   AudioBuffer buffer;
	buffer.mNumberChannels = 1;
	buffer.mDataByteSize = SYS_BUFFER_SIZE * bytesPerSample;
	buffer.mData = calloc(SYS_BUFFER_SIZE, bytesPerSample);
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0] = buffer;
	
   fftBuf = (float *)malloc(MAX_FRAMES_SIZE*sizeof(float));
   alg = [[FastFT alloc] initFT :[self getSampleRate] :[super getNumSignals] //
   :MAX_FRAMES_SIZE :MAG_THRESHOLD :[super getStartFreq] :[super getStartFreq] + [super getBandwidth]];
   
   //NSLog(TAG @"Initialized ... mDataByteSize=%ld", audioData.mDataByteSize);
}

// Set the AudioStreamBasicDescription for listening to audio data. Set the
// stream member var here as well.
- (size_t)ASBDForSoundMode
{
	// Describe format
	AudioStreamBasicDescription asbd = {0};
	size_t bytesPerSample = sizeof(SInt16);
	asbd.mFormatID = kAudioFormatLinearPCM;
	asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	asbd.mBitsPerChannel = 8 * bytesPerSample;
	asbd.mFramesPerPacket = 1;
	asbd.mChannelsPerFrame = 1;
	asbd.mBytesPerPacket = bytesPerSample * asbd.mFramesPerPacket;
	asbd.mBytesPerFrame = bytesPerSample * asbd.mChannelsPerFrame;
	asbd.mSampleRate			= [super getSampleRate];
   
	audioFormat = asbd;
	//[self printASBD:streamFormat];
   
	return bytesPerSample;
}

-(void)processAudio :(NSMutableArray *)sigFreq
{
   if (abort == true){return;}
   
   overlapIteration++;
   /*************** FFT ***************/
   // We want to deal with only floating point values here.
   //ConvertInt16ToFloat(&((SInt16*)audioData.mData)[overlapOffset], fftBuf, N);
   memset(fftBuf, 0, MAX_FRAMES_SIZE*sizeof(float));
   for (int i = 0; i < N; i++)
   {
      fftBuf[i] = (float)((SInt16 *)audioData.mData)[i + overlapOffset];
   }

   NSMutableArray *freqs = [alg getPitch :fftBuf];
   //NSLog(TAG @"Retrieved Sound Data ... overlapOffset=%d", overlapOffset);
   overlapOffset += (int) (N * OVERLAP_RATIO);

   //NSLog(TAG @"Freqs=%@", freqs);
   if ((freqs != nil) && ([freqs count] > 0))
   {
      if (sigFreq == nil)
      {
         matchCount++;
      }
      else
      {
         if ([sigFreq isEqual :freqs])
         {
            conseqMissedCounts = 0;
            matchCount++;
         }
         else
         {
            conseqMissedCounts++;
         }
      }
      sigFreq = freqs;
   }
   else
   {
      conseqMissedCounts++;
      matchCount = 0;
      sigFreq = nil;
   }
   
   if (matchCount < MATCH_THRESHOLD)
   {
      overlapIteration = overlapIteration % ((int) (SAMPLE_BUFFER_RATIO / (OVERLAP_RATIO*2)) + 1);
      if (overlapIteration == 0 || (conseqMissedCounts > CONSEQ_MISSED_THRESHOLD))
      {
         [self setReadyToRecv :true];
         if (overlapIteration > 0)
         {
            overlapIteration = conseqMissedCounts = 0;
            // NSLog(TAG @"CONSEQ_MISSED_THRESHOLD(" + CONSEQ_MISSED_THRESHOLD + ") Exceeded ...");

            // Wait for the next buffer to come in ...
            //[application restart :false];
         }
      }
      else
      {
         //NSLog(TAG @"Quick Retrieve Sound Data ..., overlapOffset=%d", overlapOffset);
         [self processAudio :sigFreq];
      }
   }
   //
   // Match Found
   //
   else
   {
      abort = true;
      [application scanIdentityCallback :sigFreq :callbackId];
   }
}

/**
 Change this function to decide what is done with incoming
 audio data from the microphone.
 Right now we copy it to our own temporary buffer.
 */
-(void)preProcessAudio :(int)inNumberFrames

{
   //NSLog(TAG @"preProcessAudio [%d]...", inNumberFrames);

	AudioBuffer sourceBuffer = bufferList.mBuffers[0];
	
   // Fill the buffer with our sampled data. If we fill our buffer, run the
	// fft.
	int read = (audioData.mDataByteSize/sizeof(SInt16) - inputIndex);

   SInt16* addr = &((SInt16 *)audioData.mData)[inputIndex];
	if (read > inNumberFrames)
   {
      memcpy(addr, sourceBuffer.mData, inNumberFrames*sizeof(SInt16));
		inputIndex += inNumberFrames;
   }
   else
   {
      memcpy(addr, sourceBuffer.mData, read*sizeof(SInt16));
      inputIndex = 0;
      Boolean readyToRecv = [self readyToRecv];

      if (readyToRecv == true)
      {
         overlapOffset = 0;
         [self setReadyToRecv :false];
         [self processAudio :nil];
      }
      else
      {
         NSLog(TAG @"Not Ready process incoming signals. Discarding data ...");
      }
   }
}

-(void)process :(ProximityID *)app :(NSString*)cbId;
{
   application = app;
   callbackId = [cbId copy];
   conseqMissedCounts = overlapOffset = overlapIteration = inputIndex = 0;
   abort = paused = false;
   [self setReadyToRecv :true];
   
   [self start];
   //NSLog(TAG @"Receiving AudioInput ...");
   //NSLog(TAG @"audioBuf.length= %d", N);
}

-(int)getMatchCountThreshold
{
   return MATCH_THRESHOLD;
}

-(int)getMaxFrameSize
{
   return MAX_FRAMES_SIZE;
}

-(int)getConseqMissedThreshold
{
   return CONSEQ_MISSED_THRESHOLD;
}

-(double)getOverlapRatio
{
   return OVERLAP_RATIO;
}

-(NSString *)getCallbackId
{
   return callbackId;
}

-(void)cleanup
{
   [self stop];
   DisposeAUGraph(processingGraph);
   [alg release];
   free(bufferList.mBuffers[0].mData);
   free(audioData.mData);
}

-(void) pause
{
   [self stop];
   NSLog(TAG @"Paused ...");
}

-(void) resume
{
   abort = paused = false;
   OSStatus status = AUGraphStart(processingGraph);
   checkStatus(status);
   NSLog(TAG @"Resume ...");
}

-(void) start
{
	OSStatus status = AUGraphInitialize(processingGraph);
   checkStatus(status);
	if (status >= 0)
   {
		AUGraphStart(processingGraph);
      stopped = false;
      //NSLog(TAG @"Start ...");
	}
   else
   {
		NSLog(TAG @"Error initializing processing graph");
	}
}
-(void) stop
{
   abort = paused = stopped = true;
   overlapOffset = overlapIteration = 0;
	if (processingGraph)
   {
      OSStatus status = AUGraphStop(processingGraph);
      checkStatus(status);
	}
   //NSLog(TAG @"Stopped ...");
}

/**
 Clean up.
 */
- (void) dealloc
{
   [self cleanup];
   AVAudioSession *session = [AVAudioSession sharedInstance];
	[session setActive:NO error:nil];
	[super dealloc];
   //NSLog(TAG @"Deallocated ...");
}

- (void)printASBD:(AudioStreamBasicDescription)asbd
{   
   char formatIDString[5];
   UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
   bcopy (&formatID, formatIDString, 4);
   formatIDString[4] = '\0';
   
   NSLog (@"  Sample Rate:         %10.0f",   asbd.mSampleRate);
   NSLog (@"  Format ID:           %10s",     formatIDString);
   NSLog (@"  Format Flags:        %10lX",    asbd.mFormatFlags);
   NSLog (@"  Bytes per Packet:    %10ld",    asbd.mBytesPerPacket);
   NSLog (@"  Frames per Packet:   %10ld",    asbd.mFramesPerPacket);
   NSLog (@"  Bytes per Frame:     %10ld",    asbd.mBytesPerFrame);
   NSLog (@"  Channels per Frame:  %10ld",    asbd.mChannelsPerFrame);
   NSLog (@"  Bits per Channel:    %10ld",    asbd.mBitsPerChannel);
}
@end
