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

+(Peer*)newPeerWithFromCArray:(uint8_t*)ipC port:(uint8_t*)portC portLength:(int)portLength{
    
    Peer *peer = [Peer new];
    
    NSString *ip = [NSString stringWithCharacters:(unsigned short*)ipC length:15];
    NSString *port = [NSString stringWithCharacters:(unsigned short*)portC length:portLength];
    
    peer.ip = ip;
    peer.port = [port integerValue];
    return peer;
    
}

-(NSString*)stringFormat {
    
    return [NSString  stringWithFormat:@"%s:%d\n",_ip,_port];
    
}


@end
