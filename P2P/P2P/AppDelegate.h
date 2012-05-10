//
//  AppDelegate.h
//  P2P
//
//  Created by Incomedia on 06/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>;

@property (assign) IBOutlet NSWindow *window;



//menu:
@property (weak) IBOutlet NSMenuItem *preferencesMenuButton;
- (IBAction)preferencesCall:(id)sender;


//search tab:
@property (weak) IBOutlet NSTextFieldCell *searchField;
@property (weak) IBOutlet NSButtonCell *searchButton;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSTextFieldCell *searchingLabel;
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

- (IBAction)prefPopupClick:(id)sender;
- (IBAction)chooseDownloadsFolder:(id)sender;



@end
