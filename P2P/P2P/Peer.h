//
//  Peer.h
//  P2P
//
//  Created by Incomedia on 06/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Peer : NSObject {
    
    NSString *ip;
    int port;
    
}

+(Peer*)newPeerWithIp:(NSString*)ip port:(int)port;
+(Peer*)newPeerWithFromCArray:(uint8_t*)ipC port:(uint8_t*)portC ;
-(NSString*)stringFormat ;

@property  NSString *ip;
@property  int port;

@end
