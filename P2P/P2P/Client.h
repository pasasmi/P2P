//
//  Client.h
//  P2P
//
//  Created by Incomedia on 09/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadEntry.h"

@interface Client : NSObject <NSTableViewDataSource>{
    
    NSMutableArray *ipList;
    int localPort;
    NSString *path;
    NSTableView *downloadTable;
}

+(Client*)newClientWithPort:(int)port andIpList:(NSMutableArray*)list withPath:(NSString*)path withDownloadTable:(NSTableView*)table;

-(int) getDownloadsInProgress;
-(void)requestIPListWithIP:(NSString *)ip local:(BOOL)local;
-(void)requestIPListWithIP:(NSString *)ip withPort:(int)port local:(BOOL)local;
-(NSArray*)findFiles:(NSString*)file serverIp:(NSString*)ip ;
-(void)requestFile:(DownloadEntry*)file;

@property NSMutableArray *ipList;
@property int localPort;
@property NSString *path;
@property NSTableView *downloadTable;

@end
