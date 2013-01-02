//
//  PGAudioAsset.m
//  PGAudio
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

#import "Communicator.h"

static float fs = 44100.0;
static int   NUM_SIGNALS = 3;
static float FREQ_GAP    = 500.0;
static float loFreq = 17000.0, hiFreq = 20000.0;

@implementation Communicator

-(id) init
{
  self = [super init];
  abort = paused = false;
  stopped = true;
  
  return self;
}

-(bool) isStopped
{
   return stopped;
}

-(int) getNumSignals
{
   return NUM_SIGNALS;
   
}

-(double) getFreqGap
{
   return FREQ_GAP;
}

-(int) getFrameCount
{
   return N;
}

-(float) getStartFreq
{
   return loFreq;
}

-(float) getSampleRate
{
   return fs;
}

-(float) getBandwidth
{
   return (hiFreq - loFreq);
}

@end
