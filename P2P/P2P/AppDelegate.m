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
#import "Server.h"
#import "Client.h"
#import "NATPMP.h"

#import <stdio.h>
#import <stdlib.h>
#import <sys/socket.h>
#import <netinet/in.h> //internet domain stuff
#import <netdb.h> //server info

@implementation AppDelegate

@synthesize window = _window;

#define LOCAL_PORT 8888
#define REMOTE_IP @"172.16.7.73"
#define REMOTE_PORT 7777


Server *server;
Client *client;
NSMutableArray *ipList;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    ipList = [NSMutableArray new];
    server = [Server newServerWithPort:LOCAL_PORT andIpList:ipList];
    client = [Client newClientWithPort:LOCAL_PORT andIpList:ipList];
    
    [ipList addObject:[Peer newPeerWithIp:REMOTE_IP port:REMOTE_PORT]];

    NSLog([NATPMP getPublicIp]);
    
    //the three threads of the server
    [NSThread detachNewThreadSelector:@selector(startPeerListServer) toTarget:server withObject:nil];
    [NSThread detachNewThreadSelector:@selector(startQueryServer) toTarget:server withObject:nil];
    [NSThread detachNewThreadSelector:@selector(startDownloadServer) toTarget:server withObject:nil];
    
    
    
}







@end
