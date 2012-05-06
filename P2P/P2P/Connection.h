//
//  Connection.h
//  P2P
//
//  Created by Incomedia on 06/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Connection : NSStream

+ (void)qNetworkAdditions_getStreamsToHostNamed:(NSString *)hostName
                                           port:(NSInteger)port
                                    inputStream:(out NSInputStream **)inputStreamPtr
                                   outputStream:(out NSOutputStream **)outputStreamPtr;

@end
