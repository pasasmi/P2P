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

+(Peer*)newPeerFromCArray:(uint8_t*)ipC port:(uint8_t*)portC {
    
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

+(Peer*)findPeerWithIp:(NSString*)ip inArrary:(NSArray*)ipList {
    
    for (Peer *p in ipList) {
        if ([p.ip compare:ip] == NSOrderedSame) {
            return p;
        }
    }
    
    return nil;
}

+(BOOL)addPeer:(Peer*)peer toArray:(NSMutableArray*)array {
	
    Peer *find = [self findPeerWithIp:peer.ip inArrary:array];
    if (find == nil) {
        [array addObject:peer];
        return true;
    }else if (peer.port != find.port) {
        find.port = peer.port;
        return true;
    }
    return false;
    
}



@end
