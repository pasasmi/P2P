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
		printf("Could not get socket descriptor. \n"); 
        return FALSE;
	}
    
	serverAddress.sin_family = AF_INET;
	serverAddress.sin_addr.s_addr = [Connection getIPIntFromString:[NATPMP getGatewayIp]];
	serverAddress.sin_port = htons(serverPort);
	
    uint16_t upPort = port>>8;
    
	char msg[] = {0,2,0,0,(char)upPort,(char)port,(char)upPort,(char)port,0,1,0,0};  // For now, this is the message we will send. 
	printf("We will send the message: \"%s\" to the server. \n", msg); 
	
	if (sendto(socketDescriptor, msg, strlen(msg), 0, (struct sockaddr *) &serverAddress, sizeof(serverAddress)) < 0) { 
		printf("Could not send data to the server. \n"); 
        return FALSE;
	}
    
    
	unsigned int msgSize = 50; // the max receivable size is msgSize. We should have this number larger than the max amount of data that we can receive. For now, this doesn't matter. 
	struct sockaddr_in clientAddress; 
	socklen_t clientAddressLength; 
	char msgR[msgSize];  // msg received will be stored here. 
    
    clientAddressLength = sizeof(clientAddress); 
    memset(msgR, 0, msgSize);  // intialize msg to zero. 
    
    printf("Waiting for socket...\n");
    if (recvfrom(socketDescriptor, msgR, msgSize, 0, (struct sockaddr *)&clientAddress, &clientAddressLength) < 0) { 
        
        printf("An error occured while receiving data... Program is terminating.\n"); 
		return FALSE;
    }
    
    printf("Request:\nVersion = %u\n",(uint16_t)msg[0]);
	printf("OP Code = %u\n",(uint16_t)msg[1]);
	printf("Reserved = %u\n",(uint16_t)*(&msg[2]));
	printf("Private port = %u\n",(uint16_t)*(&msg[4]));
	printf("Public port = %u\n",(uint16_t)*(&msg[6]));
	printf("Lifetime = %u\n\n",(uint)*(&msg[8]));

	
	
	printf("Response:\nVersion = %u\n",(uint16_t)msgR[0]);
	printf("OP Code = %u\n",(uint16_t)msgR[1]);
	printf("Result = %u\n",(uint16_t)*(&msgR[2]));
	printf("Seconds since initialized = %u\n",(uint)*(&msgR[4]));
	printf("Private port = %u\n",(uint16_t)*(&msgR[8]));
	printf("Public port = %u\n",(uint16_t)*(&msgR[10]));
	printf("Lifetime = %u\n",(uint)*(&msgR[12]));
    
    return TRUE;
}

@end
