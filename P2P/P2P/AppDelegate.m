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
@synthesize remotePortField = _remotePortField;
@synthesize prefPopover = _prefPopover;
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


#pragma mark -

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    path = [path stringByAppendingPathComponent:@"Contents/Resources/Preferences.plist"];
    pref = [NSDictionary dictionaryWithContentsOfFile:path];

    NSString *localPath	= [pref objectForKey:@"downloadPath"];
    NSString *remoteIp	= [pref objectForKey:@"initRemoteIP"];
    int remotePort		= [[pref objectForKey:@"initRemotePort"] intValue];
    int localPort		= [[pref objectForKey:@"initLocalPort"] intValue];
    
    ipList = [NSMutableArray new];
    [ipList addObject:[Peer newPeerWithIp:remoteIp port:remotePort]];
    
    server = [Server newServerWithPort:localPort andIpList:ipList withPath:localPath];
    client = [Client newClientWithPort:localPort andIpList:ipList withPath:localPath];
    
    [self setPreferencesVariables];
    
    //the three threads of the server
    [NSThread detachNewThreadSelector:@selector(startPeerListServer) toTarget:server withObject:nil];
    [NSThread detachNewThreadSelector:@selector(startQueryServer) toTarget:server withObject:nil];
    [NSThread detachNewThreadSelector:@selector(startDownloadServer) toTarget:server withObject:nil];
	
}

-(void)setPreferencesVariables 
{
    [_folderDownloadsPath setTitle:[pref objectForKey:@"downloadPath"]];
    [_remoteIPField setTitle:[pref objectForKey:@"initRemoteIP"]];
    [_remotePortField setTitle:[pref objectForKey:@"initRemotePort"]];
    [_localPortField setTitle:[pref objectForKey:@"initLocalPort"]];
    
}

#pragma mark -

- (IBAction)downloadButtonClick:(id)sender
{
}

#pragma mark -
#pragma mark Preferences popup related methods

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
    
    [_folderDownloadsPath setTitle:dirPath];
}

-(void)closePopoverAndSavePreferences
{
    
    [pref setValue:_folderDownloadsPath.title forKey:@"downloadPath"];
    [pref setValue:_remoteIPField.title forKey:@"initRemoteIP"];
    [pref setValue:_remotePortField.title forKey:@"initRemotePort"];
    [pref setValue:_localPortField.title forKey:@"initLocalPort"];
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    path = [path stringByAppendingPathComponent:@"Contents/Resources/Preferences.plist"];

    [pref writeToFile:path atomically:YES];
    
    [_prefPopover close];
}

- (void)windowWillMove:(NSNotification *)notification
{
	[self closePopoverAndSavePreferences];
}

-(void) windowWillClose:(NSNotification *)notification
{
	[NSApp terminate: nil];
}

#pragma mark -
#pragma mark table view delegate methods,finding files and downloading files

NSMutableArray *files;
NSMutableArray *sizes;

- (IBAction)searchButtonClick:(id)sender
{
    if (files == nil) files = [NSMutableArray new];
    
    NSString *find = _searchField.title;
    
    if([find compare:@""] == NSOrderedSame){
		[_searchingLabel setHidden:FALSE];
		[_progressBar startAnimation:nil];
        
		for (Peer *peer in ipList) {
            [files addObjectsFromArray:[client findFiles:find serverIp:peer.ip]];

        }
    }
	
	[_progressBar stopAnimation:nil];
	[_searchingLabel setHidden:TRUE];
}


-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    
    if (tableView == _searchTable){
        return [files count];            
    }
    

    return 0;
}

-(void)tableView:(NSTableView *)tableView 
  setObjectValue:(id)object 
  forTableColumn:(NSTableColumn *)tableColumn 
			 row:(NSInteger)row
{
    
    if (tableView == _searchTable) {
        if ([((NSCell*)(tableColumn.headerCell)).title compare:@"Name"] == NSOrderedSame){
            [object setTextField:[files objectAtIndex:row]];
        }
        else if ([((NSCell*)(tableColumn.headerCell)).title compare:@"Size"] == NSOrderedSame){
            [object setTextField:[sizes objectAtIndex:row]];
        }
    }
    
}


@end
