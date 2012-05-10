//
//  NAT-PMP.h
//  P2P
//
//  Created by Incomedia on 09/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NATPMP : NSObject

+(NSString*)getPublicIp;
+(NSString*)getGatewayIp;
+(BOOL)openPort:(uint16_t)port;

@end
