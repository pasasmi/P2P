//
//  AppDelegate.h
//  P2P
//
//  Created by Incomedia on 06/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTableViewDataSource> ;

@property (assign) IBOutlet NSWindow *window;

//search tab:
@property (weak) IBOutlet NSTextFieldCell *searchField;
@property (weak) IBOutlet NSButtonCell *searchButton;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSTextField *searchingLabel;
@property (weak) IBOutlet NSButtonCell *downloadButton;
@property (weak) IBOutlet NSTableView *searchTable;

- (IBAction)searchButtonClick:(id)sender;
- (IBAction)downloadButtonClick:(id)sender;

//Downloads tab:
@property (weak) IBOutlet NSTableView *downloadsTable;

//popup
@property (weak) IBOutlet NSPopover *prefPopover;
@property (weak) IBOutlet NSTextFieldCell *folderDownloadsPath;
@property (weak) IBOutlet NSButtonCell *chooseDownloadsPathButton;
@property (weak) IBOutlet NSTextFieldCell *localPortField;
@property (weak) IBOutlet NSTextFieldCell *remoteIPField;
@property (weak) IBOutlet NSTextFieldCell *remotePortField;


- (IBAction)prefPopupClick:(id)sender;
- (IBAction)chooseDownloadsFolder:(id)sender;


//about window
@property (weak) IBOutlet NSView *about;
- (IBAction)openAbout:(id)sender;


@end
