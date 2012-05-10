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

@implementation Server

@synthesize localPort;
@synthesize ipList;
@synthesize path;

+(Server*)newServerWithPort:(int)port andIpList:(NSMutableArray*)list withPath:(NSString*)path {
    
    Server *server  = [Server new];
    server.ipList = list;
    server.localPort = port;
    server.path = path;
    return server;
    
}

#pragma mark -
#pragma mark handle peer IP list request

-(void)startPeerListServer{
    
    int listenSocket = createListenSocket(NETWORK_SOCKET, STREAM, localPort);
    
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

-(void)startDownloadServer {
    
    int listenSocket = createListenSocket(NETWORK_SOCKET, STREAM, localPort+2);
    
    if(listenSocket <= 0)
        printf("ERROR: Failed to create QueryServerSocket\n");
	
	while (true) {
        int connection = createConnectionSocket(listenSocket);
        if(connection <= 0)
			printf("Error establishing connection\n");
		else{
            [NSThread detachNewThreadSelector:@selector(sendFileToSocket:) toTarget:self withObject:[NSNumber numberWithInt:connection]];
		}
    }
    
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

    uint8_t buff;

    while (!feof(file)) {
        buff = fgetc(file);
        write([socket intValue],&buff,1);
    }
    
    close([socket intValue]);
    
}



#pragma mark -
#pragma mark handle peer query request

-(void)startQueryServer {
    
    int listenSocket = createListenSocket(NETWORK_SOCKET, STREAM, localPort+1);
    
    if(listenSocket <= 0)
        printf("ERROR: Failed to create QueryServerSocket\n");
	
	while (true) {
        int connection = createConnectionSocket(listenSocket);
        if(connection <= 0)
			printf("Error establishing connection\n");
		else{
            [NSThread detachNewThreadSelector:@selector(newPeerQueryRequest:) toTarget:self withObject:[NSNumber numberWithInt:connection]];
		}
    }
    
}

-(void)newPeerQueryRequest:(NSNumber*)socket {
        
    NSString *search = [Connection readNSStringFromSocket:[socket intValue]];
    NSLog(search);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager subpathsAtPath:path];
    
    
	NSLog(path);
    for (NSString *file in files){
        NSString *fullPath = [path stringByAppendingPathComponent:file];
        if([file rangeOfString:search].location != NSNotFound && 
           ![[[fileManager attributesOfItemAtPath:fullPath error:NULL] objectForKey:NSFileType] isEqualToString:@"NSFileTypeDirectory"])
        {
			NSLog(search);
                [Connection sendNSString:[file stringByAppendingString:@"\n"] toSocket:[socket intValue]];
        }
    }
    
    
    close([socket intValue]);
    
}




@end
