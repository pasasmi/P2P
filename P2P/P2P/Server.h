//
//  Server.h
//  P2P
//
//  Created by Incomedia on 09/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Server : NSObject {
    
    int localPort;
    NSMutableArray *ipList;
    NSString *path;
    
}

-(void)startPeerListServer;
-(void)startDownloadServer;
-(void)startQueryServer;

+(Server*)newServerWithPort:(int)port andIpList:(NSMutableArray*)list withPath:(NSString*)path;
-(void)restartServer;
-(void)startServer;

@property int localPort;
@property NSMutableArray* ipList;
@property NSString* path;

@end
