//
//  Client.h
//  P2P
//
//  Created by Incomedia on 09/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Client : NSObject {
    
    NSMutableArray *ipList;
    int localPort;
    NSString *path;
}

+(Client*)newClientWithPort:(int)port andIpList:(NSMutableArray*)list withPath:(NSString*)path;

-(void)rquestIPListWithIP:(NSString *)ip local:(BOOL)local;
-(void)rquestIPListWithIP:(NSString *)ip withPort:(int)port local:(BOOL)local;
-(NSArray*)findFiles:(NSString*)file serverIp:(NSString*)ip ;
-(void)requestFile:(NSString*)file serverIp:(NSString*)ip;

@property NSMutableArray *ipList;
@property int localPort;
@property NSString *path;

@end
