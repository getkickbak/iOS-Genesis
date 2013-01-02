//
//  ProximityID.h
//  ProximityID
//
//  Created by Eric Chan on 12/09/12.
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
#import <CORDOVA/CDVPlugin.h>

@interface ProximityID : CDVPlugin {
   float    s_vol;
   float    s_vol_ratio;
   float    r_vol_ratio;
}

//Public Instance Methods (visible in phonegap API)
- (void) preLoadIdentity:(CDVInvokedUrlCommand*)command;
- (void) sendIdentity:(CDVInvokedUrlCommand*)command;
- (void) scanIdentityCallback :(NSMutableArray*)freqs :(NSString*)callbackId;
- (void) scanIdentity:(CDVInvokedUrlCommand*)command;
- (void) onReset;
- (void) onAppTerminate;
- (void) init:(CDVInvokedUrlCommand*)command;
- (void) restart :(Boolean)isSender;
- (void) stop:(CDVInvokedUrlCommand*)command;
- (void) setVolume:(CDVInvokedUrlCommand*)command;
@end
