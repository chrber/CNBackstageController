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

- (void)screen:(NSScreen *)toggleScreen willOpenOnEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"screen:willOpenOnEdge:");
}

- (void)screen:(NSScreen *)toggleScreen didOpenOnEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"screen:didOpenOnEdge:");
}

- (void)screen:(NSScreen *)toggleScreen willCloseOnEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"screen:willCloseOnEdgee:");
}

- (void)screen:(NSScreen *)toggleScreen didCloseOnEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"screen:didCloseOnEdge:");
}

@end
