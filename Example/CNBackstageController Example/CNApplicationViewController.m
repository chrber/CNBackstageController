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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
}

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

- (void)backstageController:(CNBackstageController *)backstageController willExpandOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"backstageController: %@ willExpandOnScreen: %@ onToggleEdge: %i", backstageController, toggleScreen, toggleEdge);
}

- (void)backstageController:(CNBackstageController *)backstageController didExpandOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"backstageController: %@ didExpandOnScreen: %@ onToggleEdge: %i", backstageController, toggleScreen, toggleEdge);
}

- (void)backstageController:(CNBackstageController *)backstageController willCollapseOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"backstageController: %@ willCollapseOnScreen: %@ onToggleEdge: %i", backstageController, toggleScreen, toggleEdge);
}

- (void)backstageController:(CNBackstageController *)backstageController didCollapseOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"backstageController: %@ didCollapseOnScreen: %@ onToggleEdge: %i", backstageController, toggleScreen, toggleEdge);
}

- (void)backstageController:(CNBackstageController *)backstageController willDragOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"backstageController: %@ willDragOnScreen: %@ onToggleEdge: %i", backstageController, toggleScreen, toggleEdge);
}

- (void)backstageController:(CNBackstageController *)backstageController didDragOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"backstageController: %@ didDragOnScreen: %@ onToggleEdge: %i", backstageController, toggleScreen, toggleEdge);
}

@end
