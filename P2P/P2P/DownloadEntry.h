//
//  DownloadEntry.h
//  P2P
//
//  Created by Incomedia on 11/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

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
