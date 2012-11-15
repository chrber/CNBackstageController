//
//  PreferenceController.m
//  Days
//
//  Created by cocoanaut.com on 20.05.12.
//  Copyright (c) 2012 cocoa:naut. All rights reserved.
//

#import "PreferencesController.h"
#import "CNBackstageController.h"


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
        self.toggleEdgeLabel.stringValue = NSLocalizedString(@"Toggle application on", @"");
        [self.toggleEdgePopupButton removeAllItems];
        [self.toggleEdgePopupButton addItemsWithTitles:[NSArray arrayWithObjects:
                                                        NSLocalizedString(@"Top Edge", @""),
                                                        NSLocalizedString(@"Bottom Edge", @""),
                                                        NSLocalizedString(@"Left Edge", @""),
                                                        NSLocalizedString(@"Right Edge", @""),
                                                        NSLocalizedString(@"Horizontal Screen Splitting", @""),
                                                        NSLocalizedString(@"Vertical Screen Splitting", @""),
                                                        nil]];


        self.toggleDisplayLabel.stringValue = NSLocalizedString(@"Show application on", @"");
        [self.toggleDisplayPopupButton removeAllItems];
        __block NSMutableArray *screens = [NSMutableArray array];
        [[NSScreen screens] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [screens addObject:[NSString stringWithFormat:@"Display %li", idx]];
        }];
        [self.toggleDisplayPopupButton addItemsWithTitles:screens];


        self.toggleSizeWidthLabel.stringValue = NSLocalizedString(@"Horizontal toggle size should be", @"");
        [self.toggleSizeWidthPopupButton removeAllItems];
        [self.toggleSizeWidthPopupButton addItemsWithTitles:[NSArray arrayWithObjects:
                                                             NSLocalizedString(@"Half of Screen Width", @""),
                                                             NSLocalizedString(@"A Quarter of Screen Width", @""),
                                                             NSLocalizedString(@"Three Quarter of Screen Width", @""),
                                                             NSLocalizedString(@"One Third of Screen Width", @""),
                                                             NSLocalizedString(@"Two Third of Screen Width", @""),
                                                             nil]];


        self.toggleSizeHeightLabel.stringValue = NSLocalizedString(@"Vertical toggle size should be", @"");
        [self.toggleSizeHeightPopupButton removeAllItems];
        [self.toggleSizeHeightPopupButton addItemsWithTitles:[NSArray arrayWithObjects:
                                                              NSLocalizedString(@"Half of Screen Height", @""),
                                                              NSLocalizedString(@"A Quarter of Screen Height", @""),
                                                              NSLocalizedString(@"Three Quarter of Screen Height", @""),
                                                              NSLocalizedString(@"One Third of Screen Height", @""),
                                                              NSLocalizedString(@"Two Third of Screen Height", @""),
                                                              nil]];

        self.useShadowsCheckbox.title = NSLocalizedString(@"Use shadows on expanded application view", @"");

        self.visualEffectLabel.stringValue = NSLocalizedString(@"Sliding areas should have a", @"");
        self.visualEffectBlackOverlayCheckbox.title = NSLocalizedString(@"Black Overlay", @"");
        self.visualEffectGaussianBlurCheckbox.title = NSLocalizedString(@"Gaussian Blur", @"");


        self.animationEffectLabel.stringValue = NSLocalizedString(@"Content of Application view should", @"");
        [self.animationEffectPopupButton removeAllItems];
        [self.animationEffectPopupButton addItemsWithTitles:[NSArray arrayWithObjects:
                                                             NSLocalizedString(@"be static", @""),
                                                             NSLocalizedString(@"fade in", @""),
                                                             NSLocalizedString(@"slide in", @""),
                                                             nil]];

        self.alphaValueLabel.stringValue = NSLocalizedString(@"Opacity of Sliding areas Overlay", @"");

    }

    [self restorePreferences];
}



// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Helper
// ---------------------------------------------------------------------------------------------------------------------

- (void)restorePreferences {
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    [self.toggleEdgePopupButton selectItemAtIndex:[self.userDefaults integerForKey:CNToggleEdgePreferencesKey]];
    [self.toggleDisplayPopupButton selectItemAtIndex:[self.userDefaults integerForKey:CNToggleDisplayPreferencesKey]];
    
    [self.toggleSizeWidthPopupButton selectItemAtIndex:[self.userDefaults integerForKey:CNToggleSizeWidthPreferencesKey]];
    [self.toggleSizeHeightPopupButton selectItemAtIndex:[self.userDefaults integerForKey:CNToggleSizeHeightPreferencesKey]];

    self.visualEffectBlackOverlayCheckbox.state = ([self.userDefaults integerForKey:CNToggleVisualEffectPreferencesKey] & CNToggleVisualEffectOverlayBlack);
    [self.alphaValueSlider setEnabled:(self.visualEffectBlackOverlayCheckbox.state == NSOnState)];
    self.visualEffectGaussianBlurCheckbox.state = ([self.userDefaults integerForKey:CNToggleVisualEffectPreferencesKey] & CNToggleVisualEffectGaussianBlur);

    [self.animationEffectPopupButton selectItemAtIndex:[self.userDefaults integerForKey:CNToggleAnimationEffectPreferencesKey]];
    self.alphaValueSlider.integerValue = [self.userDefaults integerForKey:CNToggleAlphaValuePreferencesKey];
}

- (void)defaultsChangedNotification
{
}



// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Actions
// ---------------------------------------------------------------------------------------------------------------------

- (IBAction)preferencesChangedAction:(id)sender
{

    NSUInteger visualEffects = [self.userDefaults integerForKey:CNToggleVisualEffectPreferencesKey];
    if (sender == self.visualEffectBlackOverlayCheckbox) {
        switch (self.visualEffectBlackOverlayCheckbox.state) {
            case NSOnState: visualEffects |= CNToggleVisualEffectOverlayBlack; break;
            case NSOffState: visualEffects &= ~CNToggleVisualEffectOverlayBlack; break;
        }
        [self.alphaValueSlider setEnabled:(self.visualEffectBlackOverlayCheckbox.state == NSOnState)];
    }
    else if (sender == self.visualEffectGaussianBlurCheckbox) {
        switch (self.visualEffectGaussianBlurCheckbox.state) {
            case NSOnState: visualEffects |= CNToggleVisualEffectGaussianBlur; break;
            case NSOffState: visualEffects &= ~CNToggleVisualEffectGaussianBlur; break;
        }
    }
    [self.userDefaults setInteger:visualEffects forKey:CNToggleVisualEffectPreferencesKey];

    if (sender == self.toggleEdgePopupButton) {
        [self.userDefaults setInteger:[self.toggleEdgePopupButton indexOfSelectedItem] forKey:CNToggleEdgePreferencesKey];
    }
    else if (sender == self.toggleDisplayPopupButton) {
        [self.userDefaults setInteger:[self.toggleDisplayPopupButton indexOfSelectedItem] forKey:CNToggleDisplayPreferencesKey];
    }
    else if (sender == self.toggleSizeWidthPopupButton) {
        [self.userDefaults setInteger:[self.toggleSizeWidthPopupButton indexOfSelectedItem] forKey:CNToggleSizeWidthPreferencesKey];
    }
    else if (sender == self.toggleSizeHeightPopupButton) {
        [self.userDefaults setInteger:[self.toggleSizeHeightPopupButton indexOfSelectedItem] forKey:CNToggleSizeHeightPreferencesKey];
    }
    else if (sender == self.animationEffectPopupButton) {
        [self.userDefaults setInteger:[self.animationEffectPopupButton indexOfSelectedItem] forKey:CNToggleAnimationEffectPreferencesKey];
    }
    else if (sender == self.alphaValueSlider) {
        [self.userDefaults setInteger:self.alphaValueSlider.integerValue forKey:CNToggleAlphaValuePreferencesKey];
    }
    else if (sender == self.useShadowsCheckbox) {
        [self.userDefaults setInteger:self.useShadowsCheckbox.state forKey:CNToggleUseShadowsPreferencesKey];
    }
    [self.userDefaults synchronize];

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
