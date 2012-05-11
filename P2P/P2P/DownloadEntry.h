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

@interface DownloadEntry : NSObject{
    NSString *name;
    NSString *filePath;
    NSString *ownerIP;
    int progress;
    int speed;
    int time;
    BOOL finished;
}

+(DownloadEntry*)newDownloadEntryWithName:(NSString*)name withPath:(NSString*)paht withIP:(NSString*)ip;

@property NSString *name;
@property NSString *filePath;
@property NSString *ownerIP;
@property int progress;
@property int speed;
@property int time;
@property BOOL finished;


@end
