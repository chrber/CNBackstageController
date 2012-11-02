//
//  PreferenceController.m
//  Days
//
//  Created by cocoanaut.com on 20.05.12.
//  Copyright (c) 2012 cocoa:naut. All rights reserved.
//

#import "PreferencesController.h"



typedef enum {
    toolbarItemTagGeneral       = 10,
    toolbarItemTagAppBehavior   = 20,
} toolbarItemTag;

// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Private method declaration
// ---------------------------------------------------------------------------------------------------------------------

@interface PreferencesController()
- (void)calculateSizeForView:(NSView *)subView;
- (void)restorePreferences;
- (void)defaultsChangedNotification;
@end



@implementation PreferencesController


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Initialization
// ---------------------------------------------------------------------------------------------------------------------
-(id)init {
    self = [super initWithWindowNibName:@"Preferences"];
    if (self != nil) {
        [[self window] center];
    }
    return self;
}

-(void)awakeFromNib {
    [self changeView:toolbarItemAppBehavior];
    [[[self window] toolbar] setSelectedItemIdentifier:CNPrefsToolbarItemBehaviorItenfier];

    // application behavior
    {
        self.toggleEdgeLabel.stringValue = NSLocalizedString(@"Toggle application on", @"application behavior: label for toggle edge");
        self.toggleDisplayLabel.stringValue = NSLocalizedString(@"Show application on", @"application behavior: label for toggle screen");
        self.applicationBehaviorLabel.stringValue = NSLocalizedString(@"Content of Application view", @"application behavior: label for toggle screen");

        [self.toggleEdgePopupButton removeAllItems];
        [self.toggleEdgePopupButton addItemsWithTitles:[NSArray arrayWithObjects:
                                                        NSLocalizedString(@"Top Edge", @"application behavior: content for toggle edge"),
                                                        NSLocalizedString(@"Bottom Edge", @"application behavior: content for toggle edge"),
                                                        NSLocalizedString(@"Left Edge", @"application behavior: content for toggle edge"),
                                                        NSLocalizedString(@"Right Edge", @"application behavior: content for toggle edge"),
                                                        nil]];


        [self.toggleDisplayPopupButton removeAllItems];
        __block NSMutableArray *screens = [NSMutableArray array];
        [[NSScreen screens] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [screens addObject:[NSString stringWithFormat:@"Display %li", idx]];
        }];
        [self.toggleDisplayPopupButton addItemsWithTitles:screens];

        [self.applicationBehaviorPopupButton removeAllItems];
        [self.applicationBehaviorPopupButton addItemsWithTitles:[NSArray arrayWithObjects:
                                                                 NSLocalizedString(@"should be static", @"application behavior: content for application bevavior"),
                                                                 NSLocalizedString(@"should fade in", @"application behavior: content for application bevavior"),
                                                                 NSLocalizedString(@"should slide in", @"application behavior: content for application bevavior"),
                                                                 nil]];
    }

    [self restorePreferences];
}



// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Helper
// ---------------------------------------------------------------------------------------------------------------------

- (void)restorePreferences {
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    [self.toggleEdgePopupButton selectItemAtIndex:[self.userDefaults integerForKey:kToggleEdgePrefsKey]];
    [self.toggleDisplayPopupButton selectItemAtIndex:[self.userDefaults integerForKey:kToggleDisplayPrefsKey]];
}

- (void)defaultsChangedNotification
{
}



// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Actions
// ---------------------------------------------------------------------------------------------------------------------

- (IBAction)preferencesChangedAction:(id)sender
{
    if (sender == self.toggleEdgePopupButton) {
        [self.userDefaults setInteger:[self.toggleEdgePopupButton indexOfSelectedItem] forKey:kToggleEdgePrefsKey];
    }
    if (sender == self.toggleDisplayPopupButton) {
        [self.userDefaults setInteger:[self.toggleDisplayPopupButton indexOfSelectedItem] forKey:kToggleDisplayPrefsKey];
    }
    if (sender == self.applicationBehaviorPopupButton) {
        [self.userDefaults setInteger:(1 << [self.applicationBehaviorPopupButton indexOfSelectedItem]) forKey:kApplicationViewBehaviorPrefsKey];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kDefaultsChangedNotificationKey object:nil];
}

- (IBAction)changeView:(id)sender {
    NSView *aView = nil;
    switch ([sender tag])
    {
        case toolbarItemTagAppBehavior: aView = viewAppBehavior; break;
    }
    [[self window] setTitle: [sender paletteLabel]];
    [self calculateSizeForView: aView];
}




// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Private Methods
// ---------------------------------------------------------------------------------------------------------------------

- (void)calculateSizeForView:(NSView *)subView {
    NSRect windowFrame = [[self window] frame];
    NSRect contentViewFrame = [[[self window] contentView] frame];
    windowFrame.size.height = NSHeight([subView frame]) + (NSHeight(windowFrame) - NSHeight(contentViewFrame));
    windowFrame.size.width = NSWidth([subView frame]);
    windowFrame.origin.y = NSMinY(windowFrame) - (NSHeight([subView frame]) - NSHeight(contentViewFrame));

    if ([[contentView subviews] count] != 0) {
        [[[contentView subviews] objectAtIndex:0] removeFromSuperview];
    }

    [[self window] setFrame: windowFrame display: YES animate: YES];
    [contentView setFrame: [subView frame]];
    [contentView addSubview: subView];
}

@end
