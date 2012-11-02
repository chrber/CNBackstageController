//
//  CNBackstageController.m
//
//  Created by cocoanaut.com on 10.04.12.
//  Copyright (c) 2012 cocoa:naut. All rights reserved.
//

/*
 The MIT License (MIT)
 Copyright © 2012 Frank Gregor, <phranck@cocoanaut.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the “Software”), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <QuartzCore/QuartzCore.h>
#import "CNBackstageController.h"



static CGFloat kAnimationDuration = 0.30;

typedef struct {
    CGFloat deltaX;
    CGFloat deltaY;
} CNToggleFrameDeltas;

typedef enum {
    CNToggleStateClosed = -1,
    CNToggleStateOpened = 1
} CNToggleState;




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark CNBackstageController Extension

@interface CNBackstageController()
@property (strong) NSViewController <CNBackstageDelegate> *applicationViewController;
@property (strong) NSView *applicationView;

@property (nonatomic, strong) NSView *finderSnapshotView;
@property (nonatomic, strong) NSView *finderSnapshotViewOverlay;

@property (nonatomic, assign) CNToggleState toggleState;
@property (nonatomic, strong) NSApplication *sharedApplication;
@property (nonatomic, assign) BOOL dockIsHidden;
@property (nonatomic, assign) BOOL iAmToggling;
@property (nonatomic, assign, getter = isNibInstanced) BOOL nibInstanced;
@property (nonatomic, readonly) CGRect toggleDisplayFrame;

#pragma mark - Helper
- (void)toggleViewStateOpen;
- (void)toggleViewStateClose;
- (void)toggleEffectOn;
- (void)toggleEffectOff;
- (CGRect)toggleDisplayFrame;
- (NSScreen*)toggleScreen;
- (CNToggleFrameDeltas)toggleDeltasForFrame:(NSRect)aFrame;
- (void)initializeApplicationWindow;
- (void)buildLayerHierarchy;
- (NSRect)frameForApplicationView;
- (void)makeFinderSnapshot;
- (void)resignApplicationWindow;
- (int)systemStatusBarThickness;
- (float)valueForToggleSize:(NSInteger)aToggleSize frameSize:(CGFloat)aSize;
- (void)showDock;
- (void)hideDock;
- (CGImageRef)snapshotOfDisplayWithID:(CGDirectDisplayID)displayID;
- (CGDirectDisplayID)displayIDForToggleDisplay:(CNToggleDisplay)aToggleDisplay;
- (NSScreen*)screenWithDisplayID:(CGDirectDisplayID)displayID;
@end




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation CNBackstageController

@implementation CNBackstageController

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        _toggleState                    = CNToggleStateClosed;
        _toggleEdge                     = CNToggleEdgeTop;
        _toggleSize                     = CNToggleSizeHalfScreen;
        _toggleDisplay                  = CNToggleDisplayMain;
        _toggleEffect                   = CNToggleEffectBlackOverlay;
        _applicationViewBehavior        = CNApplicationViewBehaviorStatic;
        _finderSnapshotView             = [[NSView alloc] init];
        _finderSnapshotViewOverlay      = [[NSView alloc] init];
        _applicationView                = [[NSView alloc] init];
        _iAmToggling                    = NO;
        _dockIsHidden                   = NO;
        _nibInstanced                   = NO;
        _sharedApplication              = [NSApplication sharedApplication];
        _applicationView                = nil;
        _applicationViewController      = nil;
    }
    return self;
}

- (id)initWithApplicationViewController:(NSViewController <CNBackstageDelegate> *)applicationViewController
{
    self = [self init];
    if (self) {
        _delegate = applicationViewController;
        _applicationViewController = applicationViewController;
        _applicationView = _applicationViewController.view;
    }
    return self;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors

- (void)setToggleSize:(CNToggleSize)aToggleSize
{
    if(aToggleSize < 0) {
        _toggleSize *= -1;
    }
    if(aToggleSize > NSHeight(self.toggleScreen.frame)) {
        _toggleSize = CNToggleSizeHalfScreen;

    } else {
        _toggleSize = aToggleSize;
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public API

- (void)toggleViewState
{
    if (self.iAmToggling == NO) {
        self.iAmToggling = YES;

        [NSApp activateIgnoringOtherApps:YES];

        /// inform the delegate
        [self screen:self.toggleScreen willToggleOnEdge:self.toggleEdge];
        
        switch (self.toggleState) {
            case CNToggleStateClosed: [self toggleViewStateOpen]; break;
            case CNToggleStateOpened: [self toggleViewStateClose]; break;
        }
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Helper

- (void)toggleViewStateOpen
{
    [self initializeApplicationWindow];
    [self buildLayerHierarchy];
    [self makeFinderSnapshot];
    [self hideDock];
    

    if (self.applicationViewBehavior & CNApplicationViewBehaviorFade) {
        self.applicationView.alphaValue = 0.0;
    }

    __block NSRect applicationFrame = self.applicationView.frame;
    __block NSRect finderSnapshotFrame = self.finderSnapshotView.frame;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        if (self.applicationViewBehavior & CNApplicationViewBehaviorSlide) {
            switch (self.toggleEdge) {
                case CNToggleEdgeTop:               applicationFrame.origin.y -= NSHeight(applicationFrame); break;
                case CNToggleEdgeBottom:            applicationFrame.origin.y += NSHeight(applicationFrame); break;
                case CNToggleEdgeLeft:              applicationFrame.origin.x += NSWidth(applicationFrame); break;
                case CNToggleEdgeRight:             applicationFrame.origin.x -= NSWidth(applicationFrame); break;
                case CNToggleEdgeSplitHorizontal:
                    break;
                case CNToggleEdgeSplitVertical:
                    break;
            }
        }

        if (self.applicationViewBehavior & CNApplicationViewBehaviorFade) {
            [[self.applicationView animator] setAlphaValue:1.0];
        }

        // configure the finder snapshot view
        switch (self.toggleEdge) {
            case CNToggleEdgeTop:               finderSnapshotFrame.origin.y -= floor([self toggleDeltasForFrame:finderSnapshotFrame].deltaY); break;
            case CNToggleEdgeBottom:            finderSnapshotFrame.origin.y += floor([self toggleDeltasForFrame:finderSnapshotFrame].deltaY); break;
            case CNToggleEdgeLeft:              finderSnapshotFrame.origin.x += floor([self toggleDeltasForFrame:finderSnapshotFrame].deltaX); break;
            case CNToggleEdgeRight:             finderSnapshotFrame.origin.x -= floor([self toggleDeltasForFrame:finderSnapshotFrame].deltaX); break;
            case CNToggleEdgeSplitHorizontal:
                break;
            case CNToggleEdgeSplitVertical:
                break;
        }

        [self toggleEffectOn];
        [[self.finderSnapshotView animator] setFrame:finderSnapshotFrame];
        [[self.applicationView animator] setFrame:applicationFrame];

        
    } completionHandler:^{
        self.toggleState = CNToggleStateOpened;
        self.iAmToggling = NO;

        /// inform the delegate
        [self screen:self.toggleScreen didToggleOnEdge:self.toggleEdge];
    }];
}

- (void)toggleViewStateClose
{
    __block NSRect applicationFrame = self.applicationView.frame;
    __block NSRect snapshotFrame = self.finderSnapshotView.frame;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        if (self.applicationViewBehavior & CNApplicationViewBehaviorSlide) {
            switch (self.toggleEdge) {
                case CNToggleEdgeTop:               applicationFrame.origin.y += NSHeight(applicationFrame); break;
                case CNToggleEdgeBottom:            applicationFrame.origin.y -= NSHeight(applicationFrame); break;
                case CNToggleEdgeLeft:              applicationFrame.origin.x -= NSWidth(applicationFrame); break;
                case CNToggleEdgeRight:             applicationFrame.origin.x += NSWidth(applicationFrame); break;
                case CNToggleEdgeSplitHorizontal:
                    break;
                case CNToggleEdgeSplitVertical:
                    break;
            }
        }

        if (self.applicationViewBehavior & CNApplicationViewBehaviorFade) {
            [[self.applicationView animator] setAlphaValue:0.0];
        }

        // animate the snapshot
        switch (self.toggleEdge) {
            case CNToggleEdgeTop:       snapshotFrame.origin.y += [self toggleDeltasForFrame:snapshotFrame].deltaY; break;
            case CNToggleEdgeBottom:    snapshotFrame.origin.y -= [self toggleDeltasForFrame:snapshotFrame].deltaY; break;
            case CNToggleEdgeLeft:      snapshotFrame.origin.x -= [self toggleDeltasForFrame:snapshotFrame].deltaX; break;
            case CNToggleEdgeRight:     snapshotFrame.origin.x += [self toggleDeltasForFrame:snapshotFrame].deltaX; break;
            default: break;
        }

        [self toggleEffectOff];
        [[self.applicationView animator] setFrame:applicationFrame];
        [[self.finderSnapshotView animator] setFrame:snapshotFrame];

        
    } completionHandler:^{
        [self showDock];
        [self resignApplicationWindow];
        self.iAmToggling = NO;
        self.toggleState = CNToggleStateClosed;

        /// inform the delegate
        [self screen:self.toggleScreen didToggleOnEdge:self.toggleEdge];
    }];
}

- (void)toggleEffectOn
{
    if (self.toggleEffect & CNToggleEffectBlackOverlay) {
        self.finderSnapshotViewOverlay.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
        [[self.finderSnapshotViewOverlay animator] setAlphaValue:0.75];
    }
}

- (void)toggleEffectOff
{
    if (self.toggleEffect & CNToggleEffectBlackOverlay) {
        [[self.finderSnapshotViewOverlay animator] setAlphaValue:0.0];
    }
}

- (CGRect)toggleDisplayFrame
{
    return [[self toggleScreen] frame];
}

- (NSScreen*)toggleScreen
{
    return [self screenWithDisplayID:[self displayIDForToggleDisplay:self.toggleDisplay]];
}

- (CNToggleFrameDeltas)toggleDeltasForFrame:(NSRect)aFrame
{
    CNToggleFrameDeltas frameDeltas;
    switch (self.toggleEdge) {
        case CNToggleEdgeTop:
        case CNToggleEdgeBottom: {
            frameDeltas.deltaX = 0;
            switch (self.toggleSize) {
                case CNToggleSizeHalfScreen:
                case CNToggleSizeQuarterScreen:
                case CNToggleSizeThreeQuarterScreen:
                case CNToggleSizeOneThirdScreen:
                case CNToggleSizeTwoThirdsScreen:
                    frameDeltas.deltaY = [self valueForToggleSize:self.toggleSize frameSize:NSHeight(aFrame)];
                    break;
                default:
                    frameDeltas.deltaY = self.toggleSize;
                    break;
            }
            break;
        }

        case CNToggleEdgeLeft:
        case CNToggleEdgeRight: {
            frameDeltas.deltaY = 0;
            switch (self.toggleSize) {
                case CNToggleSizeHalfScreen:
                case CNToggleSizeQuarterScreen:
                case CNToggleSizeThreeQuarterScreen:
                case CNToggleSizeOneThirdScreen:
                case CNToggleSizeTwoThirdsScreen:
                    frameDeltas.deltaX = [self valueForToggleSize:self.toggleSize frameSize:NSWidth(aFrame)];
                    break;
                default:
                    frameDeltas.deltaX = self.toggleSize;
                    break;
            }
            break;
        }

        case CNToggleEdgeSplitHorizontal:
        case CNToggleEdgeSplitVertical:
            break;
    }
    return frameDeltas;
}

- (void)initializeApplicationWindow
{
    CGDirectDisplayID displayID = [self displayIDForToggleDisplay:self.toggleDisplay];
    NSRect windowRect = NSMakeRect(0, 0, CGDisplayPixelsWide(displayID), CGDisplayPixelsHigh(displayID));

    if (self.toggleDisplay == CNToggleDisplayMain) {
        windowRect.size.height -= self.systemStatusBarThickness;
    }

    self.window = [[NSWindow alloc] initWithContentRect:windowRect
                                              styleMask:NSBorderlessWindowMask
                                                backing:NSBackingStoreBuffered
                                                  defer:NO
                                                 screen:[self screenWithDisplayID:displayID]];
    [self.window setHasShadow:NO];
    [self.window setDisplaysWhenScreenProfileChanges:YES];
    [self.window setReleasedWhenClosed:NO];
    [self.window setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"TexturedBackground-Linen-Middle"]]];
    //    [self.window setBackgroundColor:[NSColor darkGrayColor]];
    self.window.collectionBehavior = (NSWindowCollectionBehaviorDefault |
                                      NSWindowCollectionBehaviorManaged |
                                      NSWindowCollectionBehaviorFullScreenAuxiliary);

    // all layer stuff is layer backed
    [[self.window contentView] setWantsLayer:YES];
}

- (void)buildLayerHierarchy
{
    self.applicationView.frame = [self frameForApplicationView];
    self.finderSnapshotView.frame = self.window.frame;

    // Application
    [[self.window contentView] addSubview:self.applicationView];

    // Finder Snapshot
    [[self.window contentView] addSubview:self.finderSnapshotView];

    // Finder Snapshot Overlay
    self.finderSnapshotViewOverlay.alphaValue = 0.0;
    [self.finderSnapshotView addSubview:self.finderSnapshotViewOverlay];
    CNBackstageShadowView *shadowView = [[CNBackstageShadowView alloc] initWithFrame:self.finderSnapshotView.frame];
    shadowView.toggleEdge = self.toggleEdge;
    [self.finderSnapshotView addSubview:shadowView];
}

- (NSRect)frameForApplicationView
{
    NSRect resultRect = NSZeroRect;
    switch (self.toggleEdge) {
        case CNToggleEdgeTop: {
            resultRect.size = NSMakeSize(NSWidth(self.window.frame), [self toggleDeltasForFrame:self.window.frame].deltaY);
            switch (self.applicationViewBehavior) {
                case CNApplicationViewBehaviorFade:
                case CNApplicationViewBehaviorStatic:
                    resultRect.origin.y = NSHeight(self.window.frame) - NSHeight(resultRect);
                    break;

                case CNApplicationViewBehaviorSlide:
                    resultRect.origin.y = NSHeight(self.window.frame);
                    break;
            }
            break;
        }

        case CNToggleEdgeBottom: {
            resultRect.size = NSMakeSize(NSWidth(self.window.frame), [self toggleDeltasForFrame:self.window.frame].deltaY);
            switch (self.applicationViewBehavior) {
                case CNApplicationViewBehaviorFade:
                case CNApplicationViewBehaviorStatic:
                    resultRect.origin.y = 0;
                    break;

                case CNApplicationViewBehaviorSlide:
                    resultRect.origin.y = 0 - NSHeight(resultRect);
                    break;
            }
            break;
        }

        case CNToggleEdgeLeft: {
            resultRect.size = NSMakeSize([self toggleDeltasForFrame:self.window.frame].deltaX, NSHeight(self.window.frame));
            switch (self.applicationViewBehavior) {
                case CNApplicationViewBehaviorFade:
                case CNApplicationViewBehaviorStatic:
                    resultRect.origin.x = 0;
                    break;

                case CNApplicationViewBehaviorSlide:
                    resultRect.origin.x = 0 - NSWidth(resultRect);
                    break;
            }
            break;
        }

        case CNToggleEdgeRight: {
            resultRect.size = NSMakeSize([self toggleDeltasForFrame:self.window.frame].deltaX, NSHeight(self.window.frame));
            resultRect.origin.x  = self.window.frame.size.width - resultRect.size.width;
            switch (self.applicationViewBehavior) {
                case CNApplicationViewBehaviorFade:
                case CNApplicationViewBehaviorStatic:
                    resultRect.origin.x = NSWidth(self.window.frame) - NSWidth(resultRect);
                    break;

                case CNApplicationViewBehaviorSlide:
                    resultRect.origin.x = NSWidth(self.window.frame);
                    break;
            }
            break;
        }

        case CNToggleEdgeSplitHorizontal:
        case CNToggleEdgeSplitVertical:
            break;
    }
    return resultRect;
}

- (void)makeFinderSnapshot
{
    CGDirectDisplayID displayID = [self displayIDForToggleDisplay:self.toggleDisplay];
    NSRect contentViewBounds = [self.window.contentView bounds];

    CGImageRef snapshotRef = [self snapshotOfDisplayWithID:displayID];
    self.finderSnapshotView.frame = contentViewBounds;
    self.finderSnapshotView.layer.contents = (__bridge id)(snapshotRef);
    CGImageRelease(snapshotRef);

    self.finderSnapshotViewOverlay.frame = contentViewBounds;

    [self showWindow:nil];
}

- (void)resignApplicationWindow
{
    self.finderSnapshotView = [[NSView alloc] init];
    self.finderSnapshotViewOverlay = [[NSView alloc] init];
    self.window.contentView = [[NSView alloc] init];
    [self.window close];
    self.window = [NSWindow new];
}

- (int)systemStatusBarThickness
{
    return ([self displayIDForToggleDisplay:self.toggleDisplay] == CGMainDisplayID() ? [[NSStatusBar systemStatusBar] thickness] : 0);
}

- (float)valueForToggleSize:(NSInteger)aToggleSize frameSize:(CGFloat)aSize
{
    float value = 0;
    switch (aToggleSize) {
        case CNToggleSizeHalfScreen:         value = aSize /  -2.00 * -1;      break;
        case CNToggleSizeQuarterScreen:      value = aSize /  -4.00 * -1;      break;
        case CNToggleSizeThreeQuarterScreen: value = (aSize / -4.00 * -1) * 3; break;
        case CNToggleSizeOneThirdScreen:     value = aSize /  -3.00 * -1;      break;
        case CNToggleSizeTwoThirdsScreen:    value = aSize /  -1.50 * -1;      break;
    }
    return value;
}

- (void)showDock
{
    if (self.dockIsHidden) {
        self.sharedApplication.presentationOptions = NSApplicationPresentationDefault;
        self.dockIsHidden = NO;
    }
}

- (void)hideDock
{
    if ([self.toggleScreen containsDock]) {
        self.sharedApplication.presentationOptions = NSApplicationPresentationHideDock;
        self.dockIsHidden = YES;
    }
}

- (CGImageRef)snapshotOfDisplayWithID:(CGDirectDisplayID)displayID
{
    return CGDisplayCreateImageForRect(displayID, CGRectMake(0, 0 + self.systemStatusBarThickness,
                                                             NSWidth(self.toggleDisplayFrame),
                                                             NSHeight(self.toggleDisplayFrame) - self.systemStatusBarThickness));
}

- (CGDirectDisplayID)displayIDForToggleDisplay:(CNToggleDisplay)aToggleDisplay
{
    uint32_t MAX_TOGGLE_DISPLAYS = 4;   // number of supported displays
    uint32_t displayCount;
    CGDirectDisplayID toggleDisplays[MAX_TOGGLE_DISPLAYS];
    CGGetOnlineDisplayList(MAX_TOGGLE_DISPLAYS, toggleDisplays, &displayCount);

    return (aToggleDisplay > displayCount ? toggleDisplays[0]: toggleDisplays[aToggleDisplay]);
}

- (NSScreen*)screenWithDisplayID:(CGDirectDisplayID)displayID
{
    NSScreen *result;
    for (NSScreen *aScreen in [NSScreen screens]) {
        if ([[[aScreen deviceDescription] valueForKey:@"NSScreenNumber"] intValue] == displayID) {
            result = aScreen;
            break;
        }
    }
    return result;
}




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstage Delegate Callbacks

- (void)screen:(NSScreen *)toggleScreen willToggleOnEdge:(CNToggleEdge)toggleEdge
{
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate screen:self.toggleScreen willToggleOnEdge:self.toggleEdge];
    }
}

- (void)screen:(NSScreen *)toggleScreen didToggleOnEdge:(CNToggleEdge)toggleEdge
{
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate screen:self.toggleScreen didToggleOnEdge:self.toggleEdge];
    }
}

@end





/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstageShadowView

static NSColor *startColor;
static NSColor *endColor;

@interface CNBackstageShadowView ()
@end
@implementation CNBackstageShadowView

+ (void)initialize
{
    startColor = [[NSColor blackColor] colorWithAlphaComponent:0.42];
    endColor = [NSColor clearColor];
}

- (void)setToggleEdge:(CNToggleEdge)toggleEdge
{
    _toggleEdge = toggleEdge;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGRect gradientRect = NSZeroRect;
    CGFloat angle = 0;
    switch (self.toggleEdge) {
        case CNToggleEdgeTop:       gradientRect = NSMakeRect(0, NSHeight(dirtyRect)-12, NSWidth(dirtyRect), 11); angle = -90; break;
        case CNToggleEdgeRight:     gradientRect = NSMakeRect(NSWidth(dirtyRect)-12, 0, 11, NSHeight(dirtyRect)); angle = 180; break;
        case CNToggleEdgeBottom:    angle = 90; break;
        case CNToggleEdgeLeft:      gradientRect = NSMakeRect(0, 0, 11, NSHeight(dirtyRect));  angle = 0; break;
        default: break;
    }
    NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations: startColor, 0.0, endColor, 1.0, nil];
    NSBezierPath *gradienPath = [NSBezierPath bezierPathWithRect:gradientRect];
    [gradient drawInBezierPath:gradienPath angle:angle];
}

@end

