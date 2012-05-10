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
#define REMOTE_IP @"localhost"
#define REMOTE_PORT 7777


Server *server;
Client *client;
NSMutableArray *ipList;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    path = [path stringByAppendingPathComponent:@"Contents/Resources/Preferences.plist"];
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:path];

    NSString *localPath = [dic objectForKey:@"downloadPath"];
    NSString *remoteIp = [dic objectForKey:@"initRemoteIP"];
    int remotePort = [[dic objectForKey:@"initRemotePort"] intValue];
    int localPort = [[dic objectForKey:@"initLocalPort"] intValue];
    
    ipList = [NSMutableArray new];
    [ipList addObject:[Peer newPeerWithIp:remoteIp port:remotePort]];
    
    server = [Server newServerWithPort:localPort andIpList:ipList withPath:localPath];
    client = [Client newClientWithPort:localPort andIpList:ipList withPath:localPath];
    
    
    
    
    
    
    //the three threads of the server
    [NSThread detachNewThreadSelector:@selector(startPeerListServer) toTarget:server withObject:nil];
    [NSThread detachNewThreadSelector:@selector(startQueryServer) toTarget:server withObject:nil];
    [NSThread detachNewThreadSelector:@selector(startDownloadServer) toTarget:server withObject:nil];
    

}








@end
