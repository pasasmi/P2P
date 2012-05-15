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
@property (weak) IBOutlet NSButton *localConnectionCheck;


- (IBAction)prefPopupClick:(id)sender;
- (IBAction)chooseDownloadsFolder:(id)sender;

@property (weak) IBOutlet NSTextField *ipLabel;


//about window
@property (weak) IBOutlet NSView *about;
- (IBAction)openAbout:(id)sender;

//Peers tab
@property (weak) IBOutlet NSTableView *peersTable;

//magic
- (IBAction)magicButton:(id)sender;


@end
