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

#import "Server.h"
#import "Connection.h"
#import "Peer.h"

#import "libServerSocket.h"
#import <stdio.h>
#import <stdlib.h>
#import <sys/socket.h>
#import <netinet/in.h> //internet domain stuff
#import <netdb.h> //server info
#import <fcntl.h>

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
    
    [self stopServers];
    
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

-(void)stopServers {
    [self closeDownloadServer];
    [self closePeerListServer];
    [self closeQueryServer];
    
    [threads[0] cancel];
    [threads[1] cancel];
    [threads[2] cancel];
}

#pragma mark -
#pragma mark handle peer IP list request

int peerSocket;

-(void)startPeerListServer{
    
    peerSocket = createListenSocket(NETWORK_SOCKET, STREAM, localPort);
    
    if(peerSocket <= 0){
        NSLog(@"ERROR: Failed to create peer list server trying again in 1 second");
        usleep(1000000);
    }
	
	while (true) { 
        int connection = createConnectionSocket(peerSocket);
        if(connection <= 0){
			NSLog(@"Error establishing connection in peer server");
            usleep(1000000);
        }
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
    
    [Peer addPeer:[Peer newPeerFromCArray:ipTmp port:portTmp] toArray:ipList];
    
    close([socket intValue]);
}


#pragma mark -
#pragma mark handle peer download request

int downloadSocket;

-(void)startDownloadServer {
    
    downloadSocket = createListenSocket(NETWORK_SOCKET, STREAM, localPort+2);
    
    if(downloadSocket <= 0){
        NSLog(@"ERROR: Failed to create downloadServer trying again in 1 second");
        usleep(1000000);
        [self startDownloadServer];
        return;
    }
	
	while (true) {
        int connection = createConnectionSocket(downloadSocket);
        if(connection <= 0){
			NSLog(@"Error establishing connection in download server");
            usleep(1000000);
        }
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
	
	int set = 1;
	setsockopt([socket intValue], SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));//disable signal on remote socket broken.
	
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
	
	fclose(file);
    close([socket intValue]);
    
}



#pragma mark -
#pragma mark handle peer query request

int querySocket;

-(void)startQueryServer {
    
    querySocket = createListenSocket(NETWORK_SOCKET, STREAM, localPort+1);
    
    if(querySocket <= 0){
        NSLog(@"ERROR: Failed to create query server trying again in 1 second");
        usleep(1000000);
        [self startQueryServer];
        return;
    }
	
	while (true) {
        int connection = createConnectionSocket(querySocket);
        if(connection <= 0){
			NSLog(@"Error establishing connection in query server\n");
            usleep(1000000);
        }
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
