//
//  Peer.m
//  P2P
//
//  Created by Incomedia on 06/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Peer.h"

@implementation Peer

@synthesize ip=_ip;
@synthesize port=_port;

+(Peer*)newPeerWithIp:(NSString*)ip port:(int)port{
    
    Peer *peer = [Peer new];
    peer.ip = ip;
    peer.port = port;
    
    return peer;
    
}

+(Peer*)newPeerWithFromCArray:(uint8_t*)ipC port:(uint8_t*)portC {
    
    Peer *peer = [Peer new];
    
    NSString *ip = [NSString stringWithCString:(char*)ipC encoding:NSStringEncodingConversionAllowLossy];
    NSString *port = [NSString stringWithCString:(char*)portC encoding:NSStringEncodingConversionAllowLossy];    
    
    peer.ip = ip;
    peer.port = [port integerValue];
    return peer;
    
}

-(NSString*)stringFormat {
    

    return [NSString stringWithFormat:@"%@:%d\n",_ip,_port];
    
}


@end
