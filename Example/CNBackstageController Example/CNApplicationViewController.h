//
//  CNApplicationViewController.h
//  CNBackstageController Example
//
//  Created by cocoa:naut on 01.11.12.
//  Copyright (c) 2012 cocoa:naut. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CNBackstageController.h"


@interface CNApplicationViewController : NSViewController <CNBackstageDelegate>
@property (strong) IBOutlet NSButton *preferencesButton;
@property (strong) IBOutlet NSButton *terminateButton;

- (IBAction)preferencesButtonAction:(id)sender;
- (IBAction)terminateButtonAction:(id)sender;
@end
