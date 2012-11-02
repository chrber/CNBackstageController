//
//  ApplicationDelegate.m
//  CNBackstageController Example
//
//  Created by cocoa:naut on 01.11.12.
//  Copyright (c) 2012 cocoa:naut. All rights reserved.
//

#import "ApplicationDelegate.h"
#import "CNBackstageController.h"
#import "CNApplicationViewController.h"


@interface ApplicationDelegate ()
@property (strong) NSStatusItem *statusItem;
@property (strong) CNApplicationViewController *appController;
@end

@implementation ApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.image = [NSImage imageNamed:@"CNStatusbarIcon-Normal"];
    self.statusItem.alternateImage = [NSImage imageNamed:@"CNStatusbarIcon-Highlight"];
    self.statusItem.highlightMode = YES;
    self.statusItem.target = self;
    self.statusItem.action = @selector(toggleApplicationView:);

    self.appController = [[CNApplicationViewController alloc] initWithNibName:@"CNApplicationView" bundle:nil];
    self.backstageController = [[CNBackstageController alloc] initWithApplicationViewController:self.appController];
    self.backstageController.toggleEdge = CNToggleEdgeLeft;
    self.backstageController.toggleSize = CNToggleSizeQuarterScreen;
    self.backstageController.toggleDisplay = CNToggleDisplaySecond;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions

- (void)toggleApplicationView:(id)sender
{
    [self.backstageController toggleViewState];
}

@end
