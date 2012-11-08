//
//  CNApplicationViewController.m
//  CNBackstageController Example
//
//  Created by cocoa:naut on 01.11.12.
//  Copyright (c) 2012 cocoa:naut. All rights reserved.
//

#import "CNApplicationViewController.h"
#import "PreferencesController.h"


@interface CNApplicationViewController ()
@property (strong) PreferencesController *preferences;
@end

@implementation CNApplicationViewController

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions

- (IBAction)preferencesButtonAction:(id)sender
{
    if (!self.preferences)
        self.preferences = [[PreferencesController alloc] init];
    [NSApp activateIgnoringOtherApps:YES];
    // [self.prefsController.window makeKeyAndOrderFront:self];
    [self.preferences showWindow:self];
}

- (IBAction)terminateButtonAction:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstage Delegate

- (void)backstageController:(CNBackstageController *)backstageController willOpenScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"backstageController: %@ willOpenScreen: %@ onToggleEdge: %i", backstageController, toggleScreen, toggleEdge);
}

- (void)backstageController:(CNBackstageController *)backstageController didOpenScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"backstageController: %@ didOpenScreen: %@ onToggleEdge: %i", backstageController, toggleScreen, toggleEdge);
}

- (void)backstageController:(CNBackstageController *)backstageController willCloseScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"backstageController: %@ willCloseScreen: %@ onToggleEdge: %i", backstageController, toggleScreen, toggleEdge);
}

- (void)backstageController:(CNBackstageController *)backstageController didCloseScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"backstageController: %@ didCloseScreen: %@ onToggleEdge: %i", backstageController, toggleScreen, toggleEdge);
}

@end
