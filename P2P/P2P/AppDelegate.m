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
@synthesize folderDownloadsPath = _folderDownloadsPath;
@synthesize chooseDownloadsPathButton = _chooseDownloadsPathButton;
@synthesize prefPopover = _prefPopover;
@synthesize preferencesMenuButton = _preferencesMenuButton;
@synthesize downloadsTable = _downloadsTable;
@synthesize searchField = _searchField;
@synthesize searchButton = _searchButton;
@synthesize progressBar = _progressBar;
@synthesize searchingLabel = _searchingLabel;
@synthesize downloadButton = _downloadButton;
@synthesize searchTable = _searchTable;


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
   /* 
    ipList = [NSMutableArray new];
    server = [Server newServerWithPort:LOCAL_PORT andIpList:ipList];
    client = [Client newClientWithPort:LOCAL_PORT andIpList:ipList];
    
    [ipList addObject:[Peer newPeerWithIp:REMOTE_IP port:REMOTE_PORT]];

    NSLog([NATPMP getPublicIp]);
    
    //the three threads of the server
    [NSThread detachNewThreadSelector:@selector(startPeerListServer) toTarget:server withObject:nil];
    [NSThread detachNewThreadSelector:@selector(startQueryServer) toTarget:server withObject:nil];
    [NSThread detachNewThreadSelector:@selector(startDownloadServer) toTarget:server withObject:nil];
    */
    
    
}


- (IBAction)searchButtonClick:(id)sender
{
}

- (IBAction)downloadButtonClick:(id)sender
{
}

- (IBAction)preferencesCall:(id)sender {
}

- (IBAction)prefPopupClick:(id)sender
{
	if(![_prefPopover isShown])
		[_prefPopover showRelativeToRect:[sender bounds] 
								  ofView:sender 
						   preferredEdge:NSMaxYEdge];
	
	else [_prefPopover close];
}

- (IBAction)chooseDownloadsFolder:(id)sender
{
	NSString *dirPath;
	NSOpenPanel* openDialog = [NSOpenPanel openPanel];
	
	[openDialog setCanChooseFiles:FALSE];
	[openDialog setCanCreateDirectories:TRUE];
	[openDialog setCanChooseDirectories:TRUE];
	[openDialog setAllowsMultipleSelection:FALSE];
	
	if([openDialog runModal] == NSOKButton)
		dirPath = [[openDialog URL]absoluteString];
	NSLog(dirPath);

}

- (void)windowWillMove:(NSNotification *)notification
{
	[_prefPopover close];
	
}
@end
