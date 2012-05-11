//
//  Server.m
//  P2P
//
//  Created by Incomedia on 09/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Server.h"
#import "Connection.h"
#import "Peer.h"

#import "libServerSocket.h"
#import <stdio.h>
#import <stdlib.h>
#import <sys/socket.h>
#import <netinet/in.h> //internet domain stuff
#import <netdb.h> //server info

#define CHUNKSIZE 512

@implementation Server

@synthesize localPort;
@synthesize ipList;
@synthesize path;


NSThread *threads[3];

+(Server*)newServerWithPort:(int)port andIpList:(NSMutableArray*)list withPath:(NSString*)path {
    
    Server *server  = [Server new];
    server.ipList = list;
    server.localPort = port;
    server.path = path;
   
    return server;
    
}

-(void)restartServer {
    NSLog(@"server restarted");
    
    [self closeDownloadServer];
    [self closePeerListServer];
    [self closeQueryServer];
    
    [threads[0] cancel];
    [threads[1] cancel];
    [threads[2] cancel];
    
    [self startServer];
}

-(void)startServer {
     NSLog(@"server started");
    
    threads[0] = [[NSThread new] initWithTarget:self selector:@selector(startPeerListServer) object:nil];
    threads[1] = [[NSThread new] initWithTarget:self selector:@selector(startQueryServer) object:nil];
    threads[2] = [[NSThread new] initWithTarget:self selector:@selector(startDownloadServer) object:nil];
    
    [threads[0] start];
    [threads[1] start];
    [threads[2] start];
}

#pragma mark -
#pragma mark handle peer IP list request

int peerSocket;

-(void)startPeerListServer{
    
    peerSocket = createListenSocket(NETWORK_SOCKET, STREAM, localPort);
    
    if(peerSocket <= 0)
        printf("ERROR: Failed to create PeerListServer\n");
	
	while (true) { 
        int connection = createConnectionSocket(peerSocket);
        if(connection <= 0)
			printf("Error establishing connection\n");
		else{
            [NSThread detachNewThreadSelector:@selector(newPeerListRequest:) toTarget:self withObject:[NSNumber numberWithInt:connection]];
		}
    }
    
}

-(void)closePeerListServer{
    close(peerSocket);
}


-(void)newPeerListRequest:(NSNumber*)socket {
    
    uint8_t tmp = 0;
    uint8_t ipTmp[16];
    uint8_t portTmp[6];
    int count = 0;
    int startPortNumber = -1;
    int err = 0;
    
    while (tmp != '\n'){
        if ((err = read([socket intValue], &tmp, 1)) > 0 && tmp != '\n'){
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
    portTmp[count-startPortNumber]= '\0';
    
    for (int i = 0; i < [ipList count]; i++) {
        [Connection sendNSString:[[ipList objectAtIndex:i] stringFormat] toSocket:[socket intValue]];
    }
    
    [ipList addObject:[Peer newPeerFromCArray:ipTmp port:portTmp]];
    
    close([socket intValue]);
}


#pragma mark -
#pragma mark handle peer download request

int downloadSocket;

-(void)startDownloadServer {
    
    downloadSocket = createListenSocket(NETWORK_SOCKET, STREAM, localPort+2);
    
    if(downloadSocket <= 0)
        printf("ERROR: Failed to create QueryServerSocket\n");
	
	while (true) {
        int connection = createConnectionSocket(downloadSocket);
        if(connection <= 0)
			printf("Error establishing connection\n");
		else{
            [NSThread detachNewThreadSelector:@selector(sendFileToSocket:) toTarget:self withObject:[NSNumber numberWithInt:connection]];
		}
    }
    
}

-(void)closeDownloadServer {
    close(downloadSocket);
}

-(void)sendFileToSocket:(NSNumber*)socket {
    
    
    
    
    NSString *fileName = [Connection readNSStringFromSocket:[socket intValue]]; 
    
    NSString *downloadFolderPath = [path stringByAppendingPathComponent:
                                    [NSString stringWithFormat:@"/%@",fileName]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:downloadFolderPath]){
        //handle the error
        return;
    }
    
    
    
    FILE *file = fopen([downloadFolderPath UTF8String], "r");
   
	uint8_t buff[CHUNKSIZE];
	int obtained;
	
	while(!feof(file))
	{
		obtained = fread(buff, sizeof(uint8_t), CHUNKSIZE, file);
		if(!feof(file) && obtained != CHUNKSIZE)
		{
			NSLog(@"Error reading file");
			break;
		}
		if(write([socket intValue], &buff, obtained) < 0) break;
	}
	
    close([socket intValue]);
    
}



#pragma mark -
#pragma mark handle peer query request

int querySocket;

-(void)startQueryServer {
    
    querySocket = createListenSocket(NETWORK_SOCKET, STREAM, localPort+1);
    
    if(querySocket <= 0)
        printf("ERROR: Failed to create QueryServerSocket\n");
	
	while (true) {
        int connection = createConnectionSocket(querySocket);
        if(connection <= 0)
			printf("Error establishing connection\n");
		else{
            [NSThread detachNewThreadSelector:@selector(newPeerQueryRequest:) toTarget:self withObject:[NSNumber numberWithInt:connection]];
		}
    }
}

-(void)closeQueryServer {
    close(querySocket);
}

-(void)newPeerQueryRequest:(NSNumber*)socket {
    
    NSString *search = [Connection readNSStringFromSocket:[socket intValue]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager subpathsAtPath:path];
    
    
    for (NSString *file in files){
        NSString *fullPath = [path stringByAppendingPathComponent:file];
        if([[file lastPathComponent] rangeOfString:search].location != NSNotFound && 
           ![[[fileManager attributesOfItemAtPath:fullPath error:NULL] objectForKey:NSFileType] isEqualToString:@"NSFileTypeDirectory"])
        {
            [Connection sendNSString:[file stringByAppendingString:@"\n"] toSocket:[socket intValue]];
        }
    }
    
    
    close([socket intValue]);
    
}




@end
