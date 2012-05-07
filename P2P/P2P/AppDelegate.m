//
//  AppDelegate.m
//  P2P
//
//  Created by Incomedia on 06/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Connection.h"
#import "Peer.h"
#import "libServerSocket.h"

@implementation AppDelegate

@synthesize window = _window;

#define LOCAL_PORT 8888
#define SERVER_NAME @"TEST"


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    printf("starting application");
    ipList = [NSMutableArray new];
    [self startConnection];
    
    [NSThread detachNewThreadSelector:@selector(startPeerListServer) toTarget:self withObject:nil];
    
    
}

#pragma mark -
#pragma mark peer IP list request

-(void)startPeerListServer{
    
    int listenSocket = createListenSocket(NETWORK_SOCKET, STREAM, LOCAL_PORT);
    
    if(listenSocket <= 0)
        printf("ERROR: Failed to create PeerListServer\n");
	
	while (true) {
        int connection = createConnectionSocket(listenSocket);
        if(connection <= 0)
			printf("Error establishing connection\n");
		else{
            [NSThread detachNewThreadSelector:@selector(newPeerListRequest:) toTarget:self withObject:[NSNumber numberWithInt:connection]];
		}
    }
    
}


-(void)newPeerListRequest:(NSNumber*)socket {
    
    uint8_t tmp = 0;
    uint8_t ipTmp[16];
    uint8_t port[5];
    int count = 0;
    int err = 0;
    
    while (tmp != '\n'){
        if ((err = read([socket intValue], &tmp, 1)) > 0){
            if (count < 16)
                ipTmp[count++]=tmp;
            else 
                ipTmp[(count++)-16]=tmp;
        }
    }
    
    uint8_t buff[128];
    NSString *peer;
    
    for (int i = 0; i < [ipList count]; i++) {
        peer =  [ipList objectAtIndex:i];
        [peer getCString:(char*)&buff[0] maxLength:128 encoding:NSStringEncodingConversionAllowLossy];
        write([socket intValue], &buff, [peer length]);
    }
    
    [ipList addObject:[Peer newPeerWithFromCArray:ipTmp port:port portLength:count-16]];
    
    close([socket intValue]);
}


#pragma mark -
#pragma mark request for a IP list of the peer

-(void)startConnection {
    
    NSInputStream *in;
    NSOutputStream *out;
    
    [Connection qNetworkAdditions_getStreamsToHostNamed:@"127.0.0.1" port:LOCAL_PORT inputStream:&in outputStream:&out];
    
    
    [in open];
    [out open];
    
    
    //send local ip and port
    
    uint8_t buff[128];
    
    NSString *localDir = [[[NSHost currentHost] addresses] objectAtIndex:1];
    localDir = [localDir stringByAppendingFormat:@":%d",LOCAL_PORT];
    
    [localDir getCString:(char*)&buff[0] maxLength:128 encoding:NSStringEncodingConversionAllowLossy];
    
    [out write:buff maxLength:[localDir length]];
    
    //reciving ip list of the other side.
    
    uint8_t inPart = 0;
    int count = 0;
    //xxx.xxx.xxx.xxx:yyyyy
    uint8_t ipTmp[16];
    uint8_t port[5];
    
    while ([in streamStatus] == 2) {
        
        while (inPart != '\n' ){
            if ([in read:&inPart maxLength:1] > 0){
                if (count < 16)
                    ipTmp[count++]=inPart;
                else 
                    ipTmp[(count++)-16]=inPart;
            }
            
        }
        [ipList addObject:[Peer newPeerWithFromCArray:&ipTmp[0] port:&port[0] portLength:count-16]];
        inPart = 0;
        count = 0;
    }    
    
}


@end
