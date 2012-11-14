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
@property (strong) CNBackstageController *backstageController;
@property (strong) CNApplicationViewController *appController;
@property (strong) NSUserDefaults *defaults;
@end

@implementation ApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.defaults = [NSUserDefaults standardUserDefaults];
    [self.defaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]]];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(defaultsChanged:) name:kDefaultsChangedNotificationKey object:nil];
    [nc addObserver:self selector:@selector(backstageControllerNotification:) name:CNBackstageControllerWillExpandOnScreenNotification object:nil];
    [nc addObserver:self selector:@selector(backstageControllerNotification:) name:CNBackstageControllerDidExpandOnScreenNotification object:nil];
    [nc addObserver:self selector:@selector(backstageControllerNotification:) name:CNBackstageControllerWillCollapseOnScreenNotification object:nil];
    [nc addObserver:self selector:@selector(backstageControllerNotification:) name:CNBackstageControllerDidCollapseOnScreenNotification object:nil];


    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.image = [NSImage imageNamed:@"CNStatusbarIcon-Normal"];
    self.statusItem.alternateImage = [NSImage imageNamed:@"CNStatusbarIcon-Highlight"];
    self.statusItem.highlightMode = YES;
    self.statusItem.target = self;
    self.statusItem.action = @selector(toggleApplicationView:);

    self.backstageController = [CNBackstageController sharedInstance];

    self.appController = [[CNApplicationViewController alloc] initWithNibName:@"CNApplicationView" bundle:nil];
    self.backstageController.applicationViewController = self.appController;
    self.backstageController.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"TexturedBackground-Linen-Middle"]];
    [self configureBackstageController];
}

- (void)configureBackstageController
{
    self.backstageController.toggleEdge             = [self.defaults integerForKey:CNToggleEdgePreferencesKey];
    self.backstageController.toggleDisplay          = [self.defaults integerForKey:CNToggleDisplayPreferencesKey];
    self.backstageController.toggleVisualEffect     = [self.defaults integerForKey:CNToggleVisualEffectPreferencesKey];
    self.backstageController.toggleAnimationEffect  = [self.defaults integerForKey:CNToggleAnimationEffectPreferencesKey];
    self.backstageController.toggleSize             = CNMakeToggleSize(CNToggleSizeQuarterScreen, CNToggleSizeQuarterScreen);
    self.backstageController.overlayAlpha           = ([self.defaults integerForKey:CNToggleAlphaValuePreferencesKey] * 0.01);
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions

- (void)toggleApplicationView:(id)sender
{
    [self.backstageController toggleViewState];
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSNotifications

- (void)defaultsChanged:(NSNotification *)notification
{
    if ([self.backstageController currentViewState] == CNToggleStateExpanded) {
        [self.backstageController collapse];
    }
    [self configureBackstageController];
}

- (void)backstageControllerNotification:(NSNotification *)notification
{
//    CNLog(@"backstageControllerNotification: %@", notification);
}

@end
