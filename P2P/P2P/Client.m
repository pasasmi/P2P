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

#import "Client.h"
#import "Peer.h"
#import "Connection.h"
#import "NATPMP.h"
#import "DownloadEntry.h"

#import <stdio.h>
#import <stdlib.h>
#import <sys/socket.h>
#import <netinet/in.h> //internet domain stuff
#import <netdb.h> //server info

#define CHUNKSIZE 512
#define CONNECTION_ATTEMPTS 5

@implementation Client

@synthesize ipList;
@synthesize localPort;
@synthesize path;
@synthesize downloadTable;
@synthesize local;
@synthesize peersTable;

NSMutableArray *currentDownloads;
int downloadsInProgress = 0;

+(Client*)newClientWithPort:(int)port andIpList:(NSMutableArray*)list withPath:(NSString*)path withDownloadTable:(NSTableView*)downloadTable withIPTable:(NSTableView*)peersTable localConnection:(BOOL)local{
    
    Client *client  = [Client new];
    client.ipList = list;
    client.localPort = port;
    client.path = path;
    client.downloadTable = downloadTable;
    client.peersTable = peersTable;
    client.local = local;
    [downloadTable setDataSource:client];
    [peersTable setDataSource:client];
    return client;
    
}

-(int) getDownloadsInProgress
{
	return downloadsInProgress;
}

#pragma mark -
#pragma mark request for a IP list of the peer

-(void)updateIPList {
    
    [self requestIPListWithIP:((Peer*)[ipList objectAtIndex:0]).ip];
    [ipList exchangeObjectAtIndex:0 withObjectAtIndex:[ipList count]-1];
    
}

-(void)requestIPListWithIP:(NSString *)ip{
    
    [self requestIPListWithIP:ip withPort:[Peer findPeerWithIp:ip inArrary:ipList].port ];
    
}

NSString *externalIP;

-(void)requestIPListWithIP:(NSString *)ip withPort:(int)port{
    
    NSInputStream *in;
    NSOutputStream *out;
    
    [Connection qNetworkAdditions_getStreamsToHostNamed:ip port:port inputStream:&in outputStream:&out];
    
    
    [in open];
    [out open];
    
    
    //send local ip and port
    
    uint8_t buff[128];
    
    NSString *localDir;
    if (!local){
        if (externalIP == nil)
            externalIP = [NATPMP getPublicIp]; 
            
        localDir = externalIP;
    } 
    else
        localDir = [Connection getLocalIp];
    
    localDir = [localDir stringByAppendingFormat:@":%d\n",localPort];
    
    [localDir getCString:(char*)&buff[0] maxLength:128 encoding:NSStringEncodingConversionAllowLossy];
    
	int aux = 0;
    while ([in streamStatus] == NSStreamStatusOpening)
	{
		NSLog(@"try to connect in get ip list");
		if(++aux > CONNECTION_ATTEMPTS) return;
	}
    
    [out write:buff maxLength:[localDir length]];
    
    //reciving ip list of the other side.
    
    uint8_t tmp = 0;
    int count = 0;
    int startPortNumber = -1;
    //xxx.xxx.xxx.xxx:yyyyy
    uint8_t ipTmp[16];
    uint8_t portTmp[5];
    
    while ([in streamStatus] == 2) {
        
        while ([in streamStatus] == 2 && tmp != '\n' ){
            if ([in read:&tmp maxLength:1] > 0 && tmp != '\n'){
                if (tmp == ':') {
                    startPortNumber = count;
                    ipTmp[count]='\0';
                }
                else if (startPortNumber != -1)
                    portTmp[(count++)-startPortNumber]=tmp;
                else 
                    ipTmp[count++]=tmp;
            }
        }
        
        if ([in streamStatus] != 2)return;
        
        portTmp[count-startPortNumber]= '\0';
        
        if ([Peer addPeer:[Peer newPeerFromCArray:ipTmp port:portTmp] toArray:ipList]) 
            [peersTable reloadData];
        
        tmp = 0;
        count = 0;
        startPortNumber = -1;
    }    
    
}



#pragma mark -
#pragma mark functions for downlaoding file

NSTimer *updatingDownlaodInfo;

-(void)requestFile:(DownloadEntry*)file{
    
    if (currentDownloads == nil) currentDownloads = [NSMutableArray new];
    
    [currentDownloads addObject:file];
    [downloadTable reloadData];
    
    //if we are going to put an object and the counter is zero we have to create the timer updater for de downloading info
    if (downloadsInProgress == 0) {
        
        updatingDownlaodInfo = [NSTimer scheduledTimerWithTimeInterval:1.0 
                                                                target:self
                                                              selector:@selector(updateFileProperties) 
                                                              userInfo:nil
                                                               repeats:YES];
        
        [updatingDownlaodInfo setFireDate:[NSDate new]];
    }
    
    //increment by one the number in the dock Tile (we have to handle when a download is interrupted)
    downloadsInProgress ++;
    [[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%d",downloadsInProgress]];
    
    [NSThread detachNewThreadSelector:@selector(downloadFile:) toTarget:self withObject:file];
}

-(void)downloadFile:(DownloadEntry*)file{
    
    int port = [Peer findPeerWithIp:file.ownerIP inArrary:ipList].port;
    
    NSInputStream *in;
    NSOutputStream *out;
    
    [Connection qNetworkAdditions_getStreamsToHostNamed:file.ownerIP port:port+2 inputStream:&in outputStream:&out];
    
    
    [in open];
    [out open];
    
	int count = 0;
    while ([in streamStatus] == NSStreamStatusOpening)
	{
		NSLog(@"trying to connect in download file");
		if(++count > CONNECTION_ATTEMPTS)return;
	}
    
    [Connection sendNSString:[file.filePath stringByAppendingString:@"\n"] toOutputStream:out];
    
    NSString *downloadFolderPath = [path stringByAppendingPathComponent:  
                                    [NSString stringWithFormat:@"/%@",file.name]]; 
    
    
    FILE *downladFile = fopen([downloadFolderPath UTF8String], "w");
    uint8_t buff[CHUNKSIZE];
    int readed = 0;
    
    
    
    while ([in streamStatus] == NSStreamStatusOpen) {
        
        if((readed = [in read:&buff[0] maxLength:1]) > 0){
            fwrite(&buff, 1, readed, downladFile);
            file.progress+=readed;
        }
    }
    fclose(downladFile);
    [in close];
    [out close];
    
    [self setFileEnded:file];
    
    
}

-(void)updateFileProperties {
    
    for (DownloadEntry *download in currentDownloads){
        if (!download.finished){
            download.time ++;
            download.speed = (download.progress / download.time);
        } 
    }
    
    [downloadTable reloadData];
}

-(void)setFileEnded:(DownloadEntry*)file {
    file.finished = TRUE;
    file.speed = 0;
    
    downloadsInProgress --;
    if (downloadsInProgress == 0){
        [[NSApp dockTile] setBadgeLabel:@""];
        [updatingDownlaodInfo invalidate];//if the last file is downloaded we end the timer updater
    }
    else 
        [[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%d",downloadsInProgress]];
    
    [downloadTable reloadData];
}


#pragma mark -
#pragma mark functions for reuesting list of files


-(NSArray*)findFiles:(NSString*)file serverIp:(NSString*)ip {
    
    NSInputStream *in;
    NSOutputStream *out;
    
    int port = [Peer findPeerWithIp:ip inArrary:ipList].port; 
    
    [Connection qNetworkAdditions_getStreamsToHostNamed:ip port:port+1 inputStream:&in outputStream:&out];
    
    [in open];
    [out open];
    
	int count = 0;
    while ([in streamStatus] == NSStreamStatusOpening)
	{
		NSLog(@"try to connect in find files");
		if(++count > CONNECTION_ATTEMPTS) return nil;
	}
    
    [Connection sendNSString:[file stringByAppendingString:@"\n"] toOutputStream:out];
    
    NSMutableArray *files = [NSMutableArray new];
    
    while ([in streamStatus] == NSStreamStatusOpen) {
        NSString *rcv = [Connection readNSStringFromInputStream:in];
        if (![rcv compare:@""] == NSOrderedSame){
            [files addObject:rcv];
        }
    }
    
    
    return files;
    
}


#pragma mark -
#pragma mark table view delegate methods and download files



-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    
    if (tableView == downloadTable){
        return [currentDownloads count];    
    }
    else if (tableView == peersTable){
        return [ipList count];    
    }
    
    return 0;
}



- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if (aTableView == downloadTable) {
        NSCell *cell = [NSCell new];
        if ([((NSCell*)(aTableColumn.headerCell)).title compare:@"File"] == NSOrderedSame){
            [cell setTitle:((DownloadEntry*)[currentDownloads objectAtIndex:rowIndex]).name];
        }
        else if ([((NSCell*)(aTableColumn.headerCell)).title compare:@"Progress"] == NSOrderedSame){
            NSString *progressStr;
            if (((DownloadEntry*)[currentDownloads objectAtIndex:rowIndex]).finished) progressStr = @"finished";
            else {
                float progress = ((DownloadEntry*)[currentDownloads objectAtIndex:rowIndex]).progress / 8;
                if (progress > 1000000)
                    progressStr = [NSString stringWithFormat:@"%.1f MB",progress/1000000];
                else if (progress > 1000)
                    progressStr = [NSString stringWithFormat:@"%.1f KB",progress/1000];
                else
                    progressStr = [NSString stringWithFormat:@"%d B",progress];
            }
            [cell setTitle:progressStr];
        }
        else if ([((NSCell*)(aTableColumn.headerCell)).title compare:@"Speed"] == NSOrderedSame){
            NSString *speedStr;
            float speed = ((DownloadEntry*)[currentDownloads objectAtIndex:rowIndex]).speed;
            if (speed == 0) 
                speedStr = @"";
            else if (speed > 1000000)
                speedStr = [NSString stringWithFormat:@"%.1f Mb/s",speed/1000000];
            else if (speed > 1000)
                speedStr = [NSString stringWithFormat:@"%.1f Kb/s",speed/1000];
            else
                speedStr = [NSString stringWithFormat:@"%d b/s",speed];
            
            [cell setTitle:speedStr];
        }
        
        return cell;
    }
    else if (aTableView == peersTable) {
        NSCell *cell = [NSCell new];
        if ([((NSCell*)(aTableColumn.headerCell)).title compare:@"IP"] == NSOrderedSame){
            [cell setTitle:((Peer*)[ipList objectAtIndex:rowIndex]).ip];
        }
        else if ([((NSCell*)(aTableColumn.headerCell)).title compare:@"Port"] == NSOrderedSame){
            [cell setTitle:[NSString stringWithFormat:@"%d",((Peer*)[ipList objectAtIndex:rowIndex]).port]];
        }
        
        return cell;
    }
    
    return NULL;
}


@end
