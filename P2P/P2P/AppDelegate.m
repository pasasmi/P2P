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
@synthesize localPortField = _localPortField;
@synthesize remoteIPField = _remoteIPField;
@synthesize remoteNodeField = _remoteNodeField;
@synthesize saveSettingsButton = _saveSettingsButton;
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
#define REMOTE_IP @"localhost"
#define REMOTE_PORT 7777


Server *server;
Client *client;
NSMutableArray *ipList;
NSDictionary *pref;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    path = [path stringByAppendingPathComponent:@"Contents/Resources/Preferences.plist"];
    pref = [NSDictionary dictionaryWithContentsOfFile:path];

    NSString *localPath = [pref objectForKey:@"downloadPath"];
    NSString *remoteIp = [pref objectForKey:@"initRemoteIP"];
    int remotePort = [[pref objectForKey:@"initRemotePort"] intValue];
    int localPort = [[pref objectForKey:@"initLocalPort"] intValue];
    
    ipList = [NSMutableArray new];
    [ipList addObject:[Peer newPeerWithIp:remoteIp port:remotePort]];
    
    server = [Server newServerWithPort:localPort andIpList:ipList withPath:localPath];
    client = [Client newClientWithPort:localPort andIpList:ipList withPath:localPath];
    
    [self setPreferencesVariables];
    
    
    
    
    //the three threads of the server
    //[NSThread detachNewThreadSelector:@selector(startPeerListServer) toTarget:server withObject:nil];
    //[NSThread detachNewThreadSelector:@selector(startQueryServer) toTarget:server withObject:nil];
    //[NSThread detachNewThreadSelector:@selector(startDownloadServer) toTarget:server withObject:nil];
    

}

-(void)setPreferencesVariables {
    
    [_folderDownloadsPath setTitle:[pref objectForKey:@"downloadPath"]];
    
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
	
	else [self closePopoverAndSavePreferences];
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
    
}

- (IBAction)saveSettingsButtonClick:(id)sender {
}

- (void)windowWillMove:(NSNotification *)notification
{
	[self closePopoverAndSavePreferences];
	
}

-(void)closePopoverAndSavePreferences {
    
    [pref setValue:_folderDownloadsPath.title forKey:@"downloadPath"];
    [pref setValue:_remoteIPField.title forKey:@"initRemoteIP"];
//    [pref setValue:.title forKey:@"initRemotePort"];
    [pref setValue:_localPortField.title forKey:@"initLocalPort"];
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    path = [path stringByAppendingPathComponent:@"Contents/Resources/Preferences.plist"];

    [pref writeToFile:path atomically:YES];
    
    [_prefPopover close];
}




#pragma mark -
#pragma mark table view delegate methods and finding files


- (IBAction)searchButtonClick:(id)sender
{
    NSString *find = _searchField.title;
    
    if([find compare:@""] == NSOrderedSame){
        for (Peer *peer in ipList) {
            [client findFiles:find serverIp:peer.ip]; 
        }
    }
}




@end
