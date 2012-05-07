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

#import <stdio.h>
#import <stdlib.h>
#import <sys/socket.h>
#import <netinet/in.h> //internet domain stuff
#import <netdb.h> //server info

@implementation AppDelegate

@synthesize window = _window;

#define LOCAL_PORT 8888
#define SERVER_NAME @"TEST"


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    printf("starting application");
    ipList = [NSMutableArray new];
    
    //the three threads of the server
    [NSThread detachNewThreadSelector:@selector(startPeerListServer) toTarget:self withObject:nil];
    [NSThread detachNewThreadSelector:@selector(startQueryServer) toTarget:self withObject:nil];
    [NSThread detachNewThreadSelector:@selector(startDownloadServer) toTarget:self withObject:nil];
    
}

#pragma mark -
#pragma mark functions for reuesting files


-(NSArray*)findFiles:(NSString*)file serverIp:(NSString*)ip {
    
    NSInputStream *in;
    NSOutputStream *out;
    
    int port = [self findPeerWithIp:ip].port; 
    
    [Connection qNetworkAdditions_getStreamsToHostNamed:ip port:port+2 inputStream:&in outputStream:&out];
    
    
    [in open];
    [out open];
        
    [self sendNSString:file toOutputStream:out];
    
    NSMutableArray *files = [NSMutableArray new];
    
    while ([in streamStatus] != NSStreamStatusClosed) {
        [files addObject:[self readNSStringFromInputStream:in]];
    }
    
    return files;

}

#pragma mark -
#pragma mark functions for downlaoding file

-(void)requestFile:(NSString*)file serverIp:(NSString*)ip{
    
    int port = [self findPeerWithIp:ip].port+2;
    
    NSInputStream *in;
    NSOutputStream *out;
    
    [Connection qNetworkAdditions_getStreamsToHostNamed:ip port:port inputStream:&in outputStream:&out];
    
    
    [in open];
    [out open];
    
    [self sendNSString:file toOutputStream:out];
    
    NSString *downloadFolderPath = [NSHomeDirectory() stringByAppendingPathComponent:  
                                    [NSString stringWithFormat:@"Downloads/%@",file]]; 

    
    FILE *downladFile = fopen([downloadFolderPath UTF8String], "w");
    uint8_t buff[1024];
    int count = 0;
        
    while ([out streamStatus] != NSStreamStatusClosed) {
        count = [in read:&buff[0] maxLength:1024];
        fputs((char*)&buff, downladFile);
    }
    
    [in close];
    [out close];
}



#pragma mark -
#pragma mark handle peer query request

-(void)startQueryServer {
    
    int listenSocket = createListenSocket(NETWORK_SOCKET, STREAM, LOCAL_PORT+1);
    
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
    
    [self sendNSString:@"Type your query string:" toSocket:[socket intValue]];
    
    NSString *search = [self readNSStringFromSocket:[socket intValue]];
    
    NSString *downloadFolderPath = [NSHomeDirectory() stringByAppendingPathComponent:  @"Downloads/"]; 
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:downloadFolderPath error:nil];
    
    for (NSString *file in files){
        if ([file rangeOfString:search].location != NSNotFound) {
            [self sendNSString:file
                      toSocket:[socket intValue]];
        }
    }
        
    
    close([socket intValue]);
    
}

#pragma mark -
#pragma mark handle peer download request

-(void)startDownloadServer {
    
    int listenSocket = createListenSocket(NETWORK_SOCKET, STREAM, LOCAL_PORT+2);
    
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

-(void)sendFileToSocket:(NSNumber*)socket {
    
    
    
    
    NSString *fileName = [self readNSStringFromSocket:[socket intValue]]; 
    
    NSString *downloadFolderPath = [NSHomeDirectory() stringByAppendingPathComponent:
                                    [NSString stringWithFormat:@"Downloads/%@",fileName]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:downloadFolderPath]){
        //handle the error
        return;
    }

    
    NSData *file = [NSData dataWithContentsOfFile:downloadFolderPath];
    uint8_t buff[[file length]];
    unsigned int size = [file length]; 
    
    [file getBytes:&buff length:[file length]];
    
    while (size > 0) {
        size -= write([socket intValue], &buff, size);
    }
    
    close([socket intValue]);
    
}




#pragma mark -
#pragma mark handle peer IP list request

-(void)startPeerListServer{
    
    int listenSocket = createListenSocket(NETWORK_SOCKET, STREAM, LOCAL_PORT);
    
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
    uint8_t port[6];
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
                port[(count++)-startPortNumber]=tmp;
            else 
                ipTmp[count++]=tmp;
        }
    }
    port[count-startPortNumber]= '\0';
    
    for (int i = 0; i < [ipList count]; i++) {
        [self sendNSString:[[ipList objectAtIndex:i] stringFormat] toSocket:[socket intValue]];
    }
    
    [ipList addObject:[Peer newPeerFromCArray:ipTmp port:port]];
    
    close([socket intValue]);
}


#pragma mark -
#pragma mark request for a IP list of the peer

-(void)startConnectionWithIP:(NSString *)ip {
    
    [self startConnectionWithIP:ip withPort:[self findPeerWithIp:ip].port];
    
}

-(void)startConnectionWithIP:(NSString *)ip withPort:(int)port {
    
    NSInputStream *in;
    NSOutputStream *out;
    
    [Connection qNetworkAdditions_getStreamsToHostNamed:ip port:port inputStream:&in outputStream:&out];
    
    
    [in open];
    [out open];
    
    
    //send local ip and port
    
    uint8_t buff[128];
    
    NSString *localDir = [[[NSHost currentHost] addresses] objectAtIndex:1];
    localDir = [localDir stringByAppendingFormat:@":%d",LOCAL_PORT];
    
    [localDir getCString:(char*)&buff[0] maxLength:128 encoding:NSStringEncodingConversionAllowLossy];
    
    [out write:buff maxLength:[localDir length]];
    
    //reciving ip list of the other side.
    
    uint8_t tmp = 0;
    int count = 0;
    int startPortNumber = 0;
    //xxx.xxx.xxx.xxx:yyyyy
    uint8_t ipTmp[16];
    uint8_t portTmp[5];
    
    while ([in streamStatus] == 2) {
        
        while (tmp != '\n' ){
            if ([in read:&tmp maxLength:1] > 0){
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
        [ipList addObject:[Peer newPeerFromCArray:ipTmp port:portTmp]];        
        tmp = 0;
        count = 0;
        startPortNumber = 0;
    }    
    
}

#pragma mark -
#pragma mark socket functions

-(NSString*)readNSStringFromSocket:(int)socket {
    
    uint8_t tmp = 0;
    uint8_t buff[1024];
    
    int count = 0;
    int err = 0;
    
    while (tmp != '\n'){
        if ((err = read(socket, &tmp, 1)) > 0){
            buff[count++] = tmp;
        }
    }
    buff[count-1]='\0';
    
    return [NSString stringWithCString:(char*)buff encoding:NSStringEncodingConversionAllowLossy];
    
}

-(NSString*)readNSStringFromInputStream:(NSInputStream*)inputStream {
    
    uint8_t tmp = 0;
    uint8_t buff[1024];
    
    int count = 0;
    
    while (tmp != '\n'){
        if ([inputStream read:&tmp maxLength:1] > 0){
            buff[count++] = tmp;
        }
    }
    buff[count-1]='\0';
    
    return [NSString stringWithCString:(char*)buff encoding:NSStringEncodingConversionAllowLossy];
    
}

-(void)sendNSString:(NSString*)string toSocket:(int)socket {
    
    uint8_t buff[1024];
    [string getCString:(char*)&buff[0] maxLength:1024 encoding:NSStringEncodingConversionAllowLossy];
    write(socket, &buff, [string length]);
    
}


-(void)sendNSString:(NSString*)string toOutputStream:(NSOutputStream*)OutputStream {
    
    uint8_t buff[1024];
    [string getCString:(char*)&buff[0] maxLength:1024 encoding:NSStringEncodingConversionAllowLossy];
    [OutputStream write:&buff[0] maxLength:[string length]];
    
}


-(NSString*)socketIPToNSString:(int)socket {
    
    uint32_t len;
    struct sockaddr_in sin;
    
    len = sizeof(sin);
    
    if (0 != getpeername(socket,(struct sockaddr*) &sin, (socklen_t*)&len)) printf("caca");
    uint32_t ip = sin.sin_addr.s_addr;
    
    return [NSString stringWithFormat:@"%d.%d.%d.%d",
            (ip&0x000000FF),
            ((ip>>8)&0x0000FF),
            ((ip>>16)&0x00FF),
            ((ip>>24))];
    
    
    
}

#pragma mark -
#pragma mark peer list functions


-(Peer*)findPeerWithIp:(NSString*)ip {

    for (Peer *p in ipList) {
        if ([p.ip compare:ip] == NSOrderedSame) {
            return p;
        }
    }

    return nil;
}



@end
