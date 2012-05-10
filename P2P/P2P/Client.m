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

#import <stdio.h>
#import <stdlib.h>
#import <sys/socket.h>
#import <netinet/in.h> //internet domain stuff
#import <netdb.h> //server info


@implementation Client

@synthesize ipList;
@synthesize localPort;
@synthesize path;

+(Client*)newClientWithPort:(int)port andIpList:(NSMutableArray*)list withPath:(NSString *)path{
    
    Client *client  = [Client new];
    client.ipList = list;
    client.localPort = port;
    client.path = path;
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

-(void)requestFile:(NSString*)file serverIp:(NSString*)ip{
    
    int port = [Peer findPeerWithIp:ip inArrary:ipList].port;
    
    NSInputStream *in;
    NSOutputStream *out;
    
    [Connection qNetworkAdditions_getStreamsToHostNamed:ip port:port+2 inputStream:&in outputStream:&out];
    
    
    [in open];
    [out open];
    
    [Connection sendNSString:[file stringByAppendingString:@"\n"] toOutputStream:out];
    
    NSString *downloadFolderPath = [path stringByAppendingPathComponent:  
                                    [NSString stringWithFormat:@"/%@",file]]; 
    
    
    FILE *downladFile = fopen([downloadFolderPath UTF8String], "w");
    uint8_t buff;
    int count = 0;
    
    while ([out streamStatus] == NSStreamStatusOpen) {
        if([in read:&buff maxLength:1] > 0){
            fputc(buff, downladFile);
            count++;
            printf("%c",buff);
        }
    }
    close((int)downladFile);
    [in close];
    [out close];
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




@end
