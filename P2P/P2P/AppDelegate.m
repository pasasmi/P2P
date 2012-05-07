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

@implementation AppDelegate

@synthesize window = _window;

#define LOCAL_PORT 8888
#define SERVER_NAME @"TEST"


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    printf("starting application");
    ipList = [NSMutableArray new];
    //[self startConnection];
    //[NSThread detachNewThreadSelector:@selector(startPeerListServer) toTarget:self withObject:nil];
    [NSThread detachNewThreadSelector:@selector(startQueryServer) toTarget:self withObject:nil];
    
}

#pragma mark -
#pragma mark handle query server request

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
    NSMutableArray *searchedFiles = [NSMutableArray new];
    
    int count = 1;
    for (NSString *file in files){
        if ([file rangeOfString:search].location != NSNotFound) {
            [self sendNSString:[NSString stringWithFormat:@"%d %@\n",count,file] 
                      toSocket:[socket intValue]];
            [searchedFiles addObject:file];
            count++;
        }
    }
    
    [self sendNSString:@"Select response number to download: " toSocket:[socket intValue]];
    
    int response = [[self readNSStringFromSocket:[socket intValue]] intValue]-1;
    
    [self sendFile:[NSString stringWithFormat:@"%@%@",downloadFolderPath,[searchedFiles objectAtIndex:response]] toIp:@"peer ip"];
    
    close([socket intValue]);
    
}

-(void)sendFile:(NSString *)path toIp:(NSString*)ip {
    
    NSOutputStream *out;
    
    [Connection qNetworkAdditions_getStreamsToHostNamed:@"127.0.0.1" port:LOCAL_PORT+2 inputStream:NULL outputStream:&out];
    
    [out open];
    
    NSData *file = [NSData dataWithContentsOfFile:path];
    uint8_t buff[[file length]];
    unsigned int size = [file length]; 
    
    [file getBytes:&buff length:[file length]];
    
    while (size > 0) {
        size -= [out write:&buff[0] maxLength:size];
    }
}




#pragma mark -
#pragma mark peer IP list request

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
    
    [ipList addObject:[Peer newPeerWithFromCArray:ipTmp port:port]];
    
    close([socket intValue]);
}


#pragma mark -
#pragma mark request for a IP list of the peer

-(void)startConnection {
    
    NSInputStream *in;
    NSOutputStream *out;
    
    [Connection qNetworkAdditions_getStreamsToHostNamed:@"127.0.0.1" port:LOCAL_PORT inputStream:&in outputStream:&out];
    
    
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
    uint8_t port[5];
    
    while ([in streamStatus] == 2) {
        
        while (tmp != '\n' ){
            if ([in read:&tmp maxLength:1] > 0){
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
        [ipList addObject:[Peer newPeerWithFromCArray:ipTmp port:port]];        
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

-(void)sendNSString:(NSString*)string toSocket:(int)socket {
    
    uint8_t buff[1024];
    [string getCString:(char*)&buff[0] maxLength:1024 encoding:NSStringEncodingConversionAllowLossy];
    write(socket, &buff, [string length]);
    
}


@end
