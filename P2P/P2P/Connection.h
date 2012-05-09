//
//  Connection.h
//  P2P
//
//  Created by Incomedia on 06/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Connection : NSObject

+ (void)qNetworkAdditions_getStreamsToHostNamed:(NSString *)hostName
                                           port:(NSInteger)port
                                    inputStream:(out NSInputStream **)inputStreamPtr
                                   outputStream:(out NSOutputStream **)outputStreamPtr;


+(NSString*)socketIPToNSString:(int)socket;
+(void)sendNSString:(NSString*)string toOutputStream:(NSOutputStream*)OutputStream;
+(void)sendNSString:(NSString*)string toSocket:(int)socket;
+(NSString*)readNSStringFromInputStream:(NSInputStream*)inputStream;
+(NSString*)readNSStringFromSocket:(int)socket;
+(NSString*)intIPToNSString:(int)ip;

@end
