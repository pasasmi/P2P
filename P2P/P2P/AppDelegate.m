/*
P2P is an academical application. It is a peer to peer fileshareing program.
 
 Copyright (C) 2012	Jordi Bueno Dominguez, Jordi Chulia Benlloch, Pau Sastre Miguel

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
 
 
#import "AppDelegate.h"
#import "Connection.h"
#import "Peer.h"
#import "libServerSocket.h"
#import "Server.h"
#import "Client.h"
#import "NATPMP.h"
#import "DownloadEntry.h"

#import <stdio.h>
#import <stdlib.h>
#import <sys/socket.h>
#import <netinet/in.h> //internet domain stuff
#import <netdb.h> //server info
#import <libkern/OSAtomic.h>

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


@synthesize about = _about;
@synthesize window = _window;



Server *server;
Client *client;
NSMutableArray *ipList;
NSDictionary *pref;


NSMutableArray *files;
NSMutableArray *filePath;
NSMutableArray *ipRequestedFile;

volatile int32_t searchingThreadCount = 0;

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
    [Peer addPeer:[Peer newPeerWithIp:remoteIp port:remotePort] toArray:ipList];
    
    server = [Server newServerWithPort:localPort 
                             andIpList:ipList 
                              withPath:localPath];
    
    client = [Client newClientWithPort:localPort 
                             andIpList:ipList 
                              withPath:localPath 
                     withDownloadTable:_downloadsTable 
                           withIPTable:_downloadsTable
                       localConnection:TRUE];
    
    [NSTimer scheduledTimerWithTimeInterval:10.0 
                                     target:client
                                   selector:@selector(updateIPList) 
                                   userInfo:nil 
                                    repeats:YES];
    
    [self setPreferencesVariables];
    
    //the three threads of the server
    [server startServer];
	
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
    int index = _searchTable.selectedRow;
    [client requestFile:[DownloadEntry newDownloadEntryWithName:[files objectAtIndex:index]
                                                       withPath:[filePath objectAtIndex:index]
                                                         withIP:[ipRequestedFile objectAtIndex:index]]];
    
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
	
	if([openDialog runModal] == NSOKButton){
		dirPath = [[openDialog directoryURL]absoluteString];
        NSArray *path = [dirPath pathComponents];
        NSRange range = {2,[path count]-2};
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
        dirPath = [NSString pathWithComponents:[path objectsAtIndexes:indexSet]];
        dirPath = [@"/" stringByAppendingString:dirPath];
        dirPath = [dirPath stringByAppendingString:@"/"];
    }
    
    [_folderDownloadsPath setTitle:dirPath];
}

-(void)closePopoverAndSavePreferences
{
    
    if (![(NSString*)[pref objectForKey:@"downloadPath"] compare:_folderDownloadsPath.title] == NSOrderedSame){
        server.path = _folderDownloadsPath.title;
    }
    if (![(NSString*)[pref objectForKey:@"initRemoteIP"] compare:_remoteIPField.title] == NSOrderedSame){
        [ipList addObject:[Peer newPeerWithIp:_remotePortField.title port:[_remotePortField.title intValue]]];
    }
    else if (![(NSString*)[pref objectForKey:@"initRemotePort"] compare:_remotePortField.title] == NSOrderedSame){
        [Peer findPeerWithIp:_remoteIPField.title inArrary:ipList].port = [_remotePortField.title intValue];
    }
    if (![(NSString*)[pref objectForKey:@"initLocalPort"] compare:_localPortField.title] == NSOrderedSame){
        server.localPort = [_localPortField.title intValue];
        [server restartServer];
    }
    
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

-(NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	if([client getDownloadsInProgress] > 0)
	{
		NSAlert *warning = [[NSAlert alloc] init];
		[warning addButtonWithTitle:@"Exit anyway"];
		[warning addButtonWithTitle:@"Do not exit"];
		[warning setMessageText:@"WARNING: There are still ongoing downloads"];
		[warning setInformativeText:@"Ongoing downloads will be lost."];
		[warning setAlertStyle:NSWarningAlertStyle];

		if([warning runModal] == NSAlertFirstButtonReturn) {
            [server stopServers];
            return NSTerminateNow;
        }
		return NSTerminateCancel;
	}
    [server stopServers];
	return NSTerminateNow;
}

-(BOOL) windowShouldClose:(NSWindow *)self
{
	[NSApp terminate: nil];
	return FALSE;
}

-(void) windowWillEnterFullScreen:(NSNotification *)notification{
    [self closePopoverAndSavePreferences];
}
-(void) windowWillExitFullScreen:(NSNotification *)notification{
    [self closePopoverAndSavePreferences];
}

#pragma mark -
#pragma mark table view delegate methods,finding files and downloading files

- (IBAction)searchButtonClick:(id)sender
{
    files = [NSMutableArray new];
    filePath = [NSMutableArray new];
    ipRequestedFile = [NSMutableArray new];
    
    NSString *find = _searchField.title;
    
    if(! [find compare:@""] == NSOrderedSame){
        [NSThread detachNewThreadSelector:@selector(findFilesWithString:) toTarget:self withObject:find];
    }
}

-(void)findFilesWithString:(NSString*)find {
	OSAtomicIncrement32(&searchingThreadCount);
	[_searchingLabel setHidden:FALSE];
	[_progressBar startAnimation:nil];
	
    for (Peer *peer in ipList) {
        [filePath addObjectsFromArray:[client findFiles:find serverIp:peer.ip]];
        for(NSString *s in filePath) [files addObject:[s lastPathComponent]];
        for(NSString *s in files) [ipRequestedFile addObject:peer.ip];
        [_searchTable reloadData];
    }
	
	@synchronized(self)
	{
		if(OSAtomicDecrement32(&searchingThreadCount) <= 0)
		{
			[_searchingLabel setHidden:TRUE];
			[_progressBar stopAnimation:nil];
		}
	}
}


-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    
    if (tableView == _searchTable){
        return [files count];    
    }
    
    
    return 0;
}



- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if (aTableView == _searchTable) {
        NSCell *cell = [NSCell new];
        if ([((NSCell*)(aTableColumn.headerCell)).title compare:@"Name"] == NSOrderedSame){
            [cell setTitle:[files objectAtIndex:rowIndex]];
        }

        return cell;
    }
    return  NULL;
}



#pragma mark -
#pragma mark methods for the about sheet


- (IBAction)openAbout:(id)sender
{
    
	/*
	 Me parece muy cutre como queda el about este.
	 Es por culpa de usar un NSAlert, que viene por defecto con el icono y un espacio para texto
	 y DEBAJO es donde se pone el NSView, no se sustituye.
	 
	 Prefiero volver al dialogo de About original
	 
	 fdo: jorchube
	 */
	
	
    NSAlert *alert = [NSAlert new];
    [alert setAlertStyle:NSInformationalAlertStyle];
	[alert setMessageText:@""];
    [alert setIcon:[NSImage new]];
    [alert addButtonWithTitle:@"OK"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert setAccessoryView:_about];
    
    [alert beginSheetModalForWindow:_window 
                      modalDelegate:self 
                     didEndSelector:nil 
                        contextInfo:nil];
    
}










@end
