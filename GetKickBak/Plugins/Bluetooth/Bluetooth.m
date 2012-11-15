#import "Bluetooth.h"
@implementation Bluetooth
@synthesize session;
@synthesize sessionEvents;//OK=peersListChanged, KO=connexionRequested
@synthesize connexionEvents;//OK=connectedListChanged, KO=receiveData

- (void)session:(GKSession *)_session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
	NSLog(@"GKSessionDelegate:didChangeState");
    
    // Look for Connected peers
    NSMutableDictionary* peers = [[NSMutableDictionary alloc] init];
    [peers setObject:session.displayName forKey:session.peerID];
    for (NSString* peerId in [self.session peersWithConnectionState:GKPeerStateConnected])
        [peers setObject:[self.session displayNameForPeer:peerId] forKey:peerId];

	NSLog(@"%u Connexion Peers", peers.count);
    if (peers.count > 1){
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:peers];
        [result setKeepCallbackAsBool:YES];
        [self writeJavascript:[result toSuccessCallbackString:connexionEvents]];
    }
    [peers release];

    // Look for Available peers
    peers = [[NSMutableDictionary alloc] init];
    for (NSString* peerId in [self.session peersWithConnectionState:GKPeerStateAvailable])
        [peers setObject:[self.session displayNameForPeer:peerId] forKey:peerId];
    
	NSLog(@"%u Session Peers", peers.count);
    if (peers.count > 0){
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:peers];
        [result setKeepCallbackAsBool:YES];
        [self writeJavascript:[result toSuccessCallbackString:sessionEvents]];
    }
    [peers release];
}

- (void)session:(GKSession *)_session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
	NSLog(@"GKSessionDelegate:didReceiveConnectionRequestFromPeer %@",peerID);

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:peerID];
    [result setKeepCallbackAsBool:YES];
    [self writeJavascript:[result toErrorCallbackString:sessionEvents]];
}
- (void)session:(GKSession *)_session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
	NSLog(@"GKSessionDelegate:connectionWithPeerFailed %@",error);    
}
- (void)session:(GKSession *)_session didFailWithError:(NSError *)error
{
	NSLog(@"GKSessionDelegate:didFailWithError %@",error);    
}

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)_session context:(void *)context
{
	NSLog(@"GKSessionDelegate:receiveData %@",peer);
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSDictionary* dataDict = [[unarchiver decodeObjectForKey:@"data"] retain];
    [unarchiver finishDecoding];
    if (dataDict && dataDict.count)
    {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dataDict];
        [result setKeepCallbackAsBool:YES];
        [self writeJavascript:[result toErrorCallbackString:connexionEvents]];
    }
    
    [unarchiver release];
    [dataDict release];
}

//function(name, availablePeerListChanged, connexionRequested)
- (void) startSession:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSLog(@"startSession");

    [sessionEvents release];
    sessionEvents = nil;
    sessionEvents = [[NSMutableString alloc] initWithString:[arguments objectAtIndex:0]];
    
    session = [[GKSession alloc] initWithSessionID:@"TudorSessionID" displayName:[options objectForKey:@"name"] sessionMode:GKSessionModePeer];
    session.delegate = self;
    session.available = YES;
    
    NSMutableString* peerId = [[NSMutableString alloc] initWithString:@"window.plugins.bluetooth.userId='"];
    [peerId appendString:session.peerID];
    [peerId appendString:@"';"];
    [self writeJavascript:peerId];
    [peerId dealloc];
}

- (void) setSessionAvailable:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
{
	NSLog(@"setSessionAvailable");
    session.available = ([options objectForKey:@"available"] == @"true");
}

//function()
- (void) stopSession:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSLog(@"stopSession");
    [sessionEvents release];
    sessionEvents = nil;
    [session release];
    session = nil;
}

//function(peerId)
- (void) connectTo:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSLog(@"connectTo");
    [session connectToPeer:[options objectForKey:@"peerId"] withTimeout:5000];
}

//function(peerId)
- (void) acceptConnexion:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
{
	NSLog(@"acceptConnexion");
    [session acceptConnectionFromPeer:[options objectForKey:@"peerId"] error:nil];
}

//function(receiveHandler, connectedPeersChange)
- (void) setConnexionEvents:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
{
    [connexionEvents release];
    connexionEvents = nil;
    connexionEvents = [[NSMutableString alloc] initWithString:[arguments objectAtIndex:0]];
    [session setDataReceiveHandler:self withContext:nil];
}

//function()
- (void) disconnect:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSLog(@"disconnect");
    [connexionEvents release];
    connexionEvents = nil;
    [session disconnectFromAllPeers];
}

//function(data)
- (void) sendDataToAll:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSLog(@"sendDataToAll");    
    
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:[options objectForKey:@"data"] forKey:@"data"];
    [archiver finishEncoding];
    [session sendDataToAllPeers:data withDataMode:GKSendDataReliable error:nil];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[options objectForKey:@"data"]];
    [result setKeepCallbackAsBool:YES];
    [self writeJavascript:[result toErrorCallbackString:connexionEvents]];
}

//function(data)
- (void) sendData:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSLog(@"sendData");
   
   NSArray *peers = [options objectForKey:@"peers"];
   NSMutableData *data = [[NSMutableData alloc] init];
   NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
   [archiver encodeObject:[options objectForKey:@"data"] forKey:@"data"];
   [archiver finishEncoding];
   [session sendData:data toPeers:peers withDataMode:GKSendDataReliable error:nil];
   
   CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[options objectForKey:@"data"]];
   [result setKeepCallbackAsBool:YES];
   [self writeJavascript:[result toErrorCallbackString:connexionEvents]];
}

@end
