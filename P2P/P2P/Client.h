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

@property NSMutableArray *ipList;
@property int localPort;

@end
