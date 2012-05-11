//
//  Client.m
//  P2P
//
//  Created by Incomedia on 09/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

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


@implementation Client

@synthesize ipList;
@synthesize localPort;
@synthesize path;
@synthesize downloadTable;

NSMutableArray *currentDownloads;

+(Client*)newClientWithPort:(int)port andIpList:(NSMutableArray*)list withPath:(NSString *)path withDownloadTable:(NSTableView *)table{
    
    Client *client  = [Client new];
    client.ipList = list;
    client.localPort = port;
    client.path = path;
    client.downloadTable = table;
    [table setDataSource:client];
    return client;
    
}

#pragma mark -
#pragma mark request for a IP list of the peer

-(void)requestIPListWithIP:(NSString *)ip local:(BOOL)local {
    
    [self requestIPListWithIP:ip withPort:[Peer findPeerWithIp:ip inArrary:ipList].port local:local];
    
}

-(void)requestIPListWithIP:(NSString *)ip withPort:(int)port local:(BOOL)local{
    
    NSInputStream *in;
    NSOutputStream *out;
    
    [Connection qNetworkAdditions_getStreamsToHostNamed:ip port:port inputStream:&in outputStream:&out];
    
    
    [in open];
    [out open];
    
    
    //send local ip and port
    
    uint8_t buff[128];
    
    NSString *localDir;
    if (!local)
        localDir = [NATPMP getPublicIp];
    else
        localDir = [Connection getLocalIp];
    
    localDir = [localDir stringByAppendingFormat:@":%d\n",localPort];
    
    [localDir getCString:(char*)&buff[0] maxLength:128 encoding:NSStringEncodingConversionAllowLossy];
    
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
        
        [ipList addObject:[Peer newPeerFromCArray:ipTmp port:portTmp]];        
        tmp = 0;
        count = 0;
        startPortNumber = -1;
    }    
    
}



#pragma mark -
#pragma mark functions for downlaoding file

-(void)requestFile:(DownloadEntry*)file{
    
    if (currentDownloads == nil) currentDownloads = [NSMutableArray new];
    
    [currentDownloads addObject:file];
    [downloadTable reloadData];
    
    [NSThread detachNewThreadSelector:@selector(downloadFile:) toTarget:self withObject:file];
}

-(void)downloadFile:(DownloadEntry*)file{
    
    int port = [Peer findPeerWithIp:file.ownerIP inArrary:ipList].port;
    
    NSInputStream *in;
    NSOutputStream *out;
    
    [Connection qNetworkAdditions_getStreamsToHostNamed:file.ownerIP port:port+2 inputStream:&in outputStream:&out];
    
    
    [in open];
    [out open];
    
    while ([in streamStatus] == NSStreamStatusOpening) NSLog(@"trying to connect");
    
    [Connection sendNSString:[file.filePath stringByAppendingString:@"\n"] toOutputStream:out];
    
    NSString *downloadFolderPath = [path stringByAppendingPathComponent:  
                                    [NSString stringWithFormat:@"/%@",file.name]]; 
    
    
    FILE *downladFile = fopen([downloadFolderPath UTF8String], "w");
    uint8_t buff;
    
    
    long timeInterVal = time(NULL)+1;
    
    while ([in streamStatus] == NSStreamStatusOpen) {
        
        if (time(NULL)>timeInterVal) {
            timeInterVal = time(NULL)+1; 
            [self updateFileProperties:file];
        } 
        
        if([in read:&buff maxLength:1] > 0){
            fputc(buff, downladFile);
            file.progress++;
        }
    }
    fclose(downladFile);
    [in close];
    [out close];
    
    [self setFileEnded:file];
    
    //[currentDownloads removeObject:file];
    //[downloadTable reloadData];
}

-(void)updateFileProperties:(DownloadEntry*)file {
    
    file.time ++;
    
    file.speed = (file.progress / file.time);
    
    [downloadTable reloadData];
}

-(void)setFileEnded:(DownloadEntry*)file {
    file.finished = TRUE;
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
    
    while ([in streamStatus] == NSStreamStatusOpening) NSLog(@"try to connect");
    
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
            if (speed > 1000000)
                speedStr = [NSString stringWithFormat:@"%.1f Mb/s",speed/1000000];
            else if (speed > 1000)
                speedStr = [NSString stringWithFormat:@"%.1f Kb/s",speed/1000];
            else
                speedStr = [NSString stringWithFormat:@"%d b/s",speed];
            
            [cell setTitle:speedStr];
        }
        else if ([((NSCell*)(aTableColumn.headerCell)).title compare:@"Total Size"] == NSOrderedSame){
            [cell setTitle:[NSString stringWithFormat:@"%d",((DownloadEntry*)[currentDownloads objectAtIndex:rowIndex]).total]];
        }
        return cell;
    }
    
    return NULL;
}


@end
