#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>
#import <GameKit/GameKit.h>
#import <Cordova/CDVPlugin.h>

@interface Bluetooth : CDVPlugin<GKSessionDelegate> {
    GKSession       *session;
    NSMutableString *sessionEvents;
    NSMutableString *connexionEvents;
//    int              mode;//0=listen, 1=peer, 2=guest, 3=host
}
@property (nonatomic, retain) GKSession       *session;
@property (nonatomic, retain) NSMutableString *sessionEvents;//OK=peersListChanged, KO=connexionRequested
@property (nonatomic, retain) NSMutableString *connexionEvents;//OK=connectedListChanged, KO=receiveData

- (void) startSession       :(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) setSessionAvailable:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) stopSession        :(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

- (void) connectTo          :(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) acceptConnexion    :(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) setConnexionEvents :(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) disconnect         :(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

- (void) sendDataToAll      :(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end
