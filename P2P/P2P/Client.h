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

#import <Foundation/Foundation.h>
#import "DownloadEntry.h"

@interface Client : NSObject <NSTableViewDataSource>{
    
    NSMutableArray *ipList;
    int localPort;
    NSString *path;
    NSTableView *downloadTable;
    NSTableView *ipTable;
    BOOL local;
}

+(Client*)newClientWithPort:(int)port andIpList:(NSMutableArray*)list withPath:(NSString*)path withDownloadTable:(NSTableView*)downloadTable withIPTable:(NSTableView*)ipTable localConnection:(BOOL)local;

-(int) getDownloadsInProgress;
-(void)requestIPListWithIP:(NSString *)ip ;
-(void)requestIPListWithIP:(NSString *)ip withPort:(int)port ;
-(NSArray*)findFiles:(NSString*)file serverIp:(NSString*)ip ;
-(void)requestFile:(DownloadEntry*)file;

@property NSMutableArray *ipList;
@property int localPort;
@property NSString *path;
@property NSTableView *downloadTable;
@property BOOL local;
@property NSTableView *ipTable;

@end
