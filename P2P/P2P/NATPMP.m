//
//  NAT-PMP.m
//  P2P
//
//  Created by Incomedia on 09/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NATPMP.h"
#import "Connection.h"

#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <string.h>

@implementation NATPMP

+(NSString*)getPublicIp {
    
    int socketDescriptor; 					
	struct sockaddr_in serverAddress; 		
	uint16_t serverPort = 5351; 	
	
	if ((socketDescriptor = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		printf("Problem getting public ip. \n"); 
        return @"";
	}

	serverAddress.sin_family = AF_INET;
	serverAddress.sin_addr.s_addr = [Connection getIPIntFromString:[NATPMP getGatewayIp]];
	serverAddress.sin_port = htons(serverPort);
	
	char msg[] = {0,0};  // For now, this is the message we will send. 
	printf("We will send the message: \"%s\" to the server. \n", msg); 
	
	if (sendto(socketDescriptor, msg, strlen(msg), 0, (struct sockaddr *) &serverAddress, sizeof(serverAddress)) < 0) { 
		printf("Could not send data to the server. \n"); 
        return @"";
	}
    
    
	unsigned int msgSize = 100; // the max receivable size is msgSize. We should have this number larger than the max amount of data that we can receive. For now, this doesn't matter. 
	struct sockaddr_in clientAddress; 
	socklen_t clientAddressLength; 
	char msgR[msgSize];  // msg received will be stored here. 
    
    clientAddressLength = sizeof(clientAddress); 
    memset(msgR, 0, msgSize);  // intialize msg to zero. 
    
    printf("waiting for socket");
    if (recvfrom(socketDescriptor, msgR, msgSize, 0, (struct sockaddr *)&clientAddress, &clientAddressLength) < 0) { 
        
        printf("An error occured while receiving data... Program is terminating. "); 
		
    }
    
    int *dir = (int*)&msgR[8];
    
    return [Connection intIPToNSString:*dir];
    

}

+(NSString*)getGatewayIp {
    
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/sbin/route"];
    
    NSArray *arguments;
    arguments = [NSArray arrayWithObjects: @"-n",@"get",@"0.0.0.0", nil];
    [task setArguments: arguments]; 
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    int length = [data length];
    
    int8_t buff[length];
    
    [data getBytes:buff length:length];
    
    NSString *ip = [NSString stringWithCString:(char*)buff encoding:NSStringEncodingConversionAllowLossy];
    NSRange location = [ip rangeOfString:@"gateway: "];
    location.location += location.length;
    location.length = 15;
    
    return [[[ip substringWithRange:location] componentsSeparatedByString:@"\n"] objectAtIndex:0];
    
    
}


+(BOOL)openPort:(uint16_t)port {
    
    
    int socketDescriptor; 					
	struct sockaddr_in serverAddress; 		
	uint16_t serverPort = 5351; 	
	
	if ((socketDescriptor = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		printf("Problem getting public ip. \n"); 
        return FALSE;
	}
    
	serverAddress.sin_family = AF_INET;
	serverAddress.sin_addr.s_addr = [Connection getIPIntFromString:[NATPMP getGatewayIp]];
	serverAddress.sin_port = htons(serverPort);
	
    
    
	char msg[] = {0,2,0,0,(char)*(&port),(char)*(&port+1),(char)*(&port),(char)*(&port+1),0,1,0,0};  // For now, this is the message we will send. 
	printf("We will send the message: \"%s\" to the server. \n", msg); 
	
	if (sendto(socketDescriptor, msg, strlen(msg), 0, (struct sockaddr *) &serverAddress, sizeof(serverAddress)) < 0) { 
		printf("Could not send data to the server. \n"); 
        return FALSE;
	}
    
    
	unsigned int msgSize = 100; // the max receivable size is msgSize. We should have this number larger than the max amount of data that we can receive. For now, this doesn't matter. 
	struct sockaddr_in clientAddress; 
	socklen_t clientAddressLength; 
	char msgR[msgSize];  // msg received will be stored here. 
    
    clientAddressLength = sizeof(clientAddress); 
    memset(msgR, 0, msgSize);  // intialize msg to zero. 
    
    printf("waiting for socket");
    if (recvfrom(socketDescriptor, msgR, msgSize, 0, (struct sockaddr *)&clientAddress, &clientAddressLength) < 0) { 
        
        printf("An error occured while receiving data... Program is terminating. "); 
		return FALSE;
    }
    
    uint16_t *dir = (uint16_t*)&msgR[2];

    printf("\nresult = %u\n",(uint16_t)msg[4]);
    
    return TRUE;
    
    
}




@end
