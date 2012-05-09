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
}

+(Client*)newClientWithPort:(int)port andIpList:(NSMutableArray*)list;

-(void)rquestIPListWithIP:(NSString *)ip ;
-(void)rquestIPListWithIP:(NSString *)ip withPort:(int)port ;
-(NSArray*)findFiles:(NSString*)file serverIp:(NSString*)ip ;
-(void)requestFile:(NSString*)file serverIp:(NSString*)ip;

@property NSMutableArray *ipList;
@property int localPort;

@end
