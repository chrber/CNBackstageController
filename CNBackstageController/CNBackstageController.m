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



static CGFloat kAnimationDuration = 0.25;

typedef struct {
    CGFloat deltaX;
    CGFloat deltaY;
} CNToggleFrameDeltas;

CNToggleFrameDeltas CNMakeToggleFrameDeltas(CGFloat deltaX, CGFloat deltaY) {
    CNToggleFrameDeltas frameDeltas;
    frameDeltas.deltaX = deltaX;
    frameDeltas.deltaY = deltaY;
    return frameDeltas;
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark CNBackstageController Extension

@interface CNBackstageController()
@property (strong) NSView *applicationView;

@property (strong) CNBackstageShadowView *shadowView;
@property (strong) NSView *viewOfFirstPartialDisplaySnapshot;
@property (strong) NSView *overlayOfFirstPartialDisplaySnapshot;
@property (strong) NSView *viewOfSecondPartialDisplaySnapshot;
@property (strong) NSView *overlayOfSecondPartialDisplaySnapshot;

@property (assign) CNToggleState toggleState;
@property (assign) BOOL dockIsHidden;
@property (assign) BOOL toggleAnimationIsRunning;
@property (readonly) CGRect frameOfCurrentToggleDisplay;

#pragma mark - Helper
- (void)changeViewStateToOpen;
- (void)changeViewStateToClose;
- (void)activateVisualEffects;
- (void)deactivateVisualEffects;
- (NSScreen*)screenOfCurrentToggleDisplay;
- (CNToggleFrameDeltas)toggleDeltasForFrame:(NSRect)aFrame;
- (void)initializeApplicationWindow;
- (void)buildLayerHierarchy;
- (NSRect)frameOfApplicationView;
- (void)createSnapshotOfCurrentToggleDisplay;
- (void)resignApplicationWindow;
- (int)thicknessOfSystemStatusBarForCurrentToggleDisplay;
- (float)valueForToggleSize:(NSInteger)aToggleSize frameSize:(CGFloat)aSize;
- (void)showDock;
- (void)hideDock;
- (CGImageRef)snapshotOfDisplayWithID:(CGDirectDisplayID)displayID;
- (CGDirectDisplayID)displayIDForCurrentToggleDisplay:(CNToggleDisplay)aToggleDisplay;
- (NSScreen*)screenForDisplayWithID:(CGDirectDisplayID)displayID;
@end




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation CNBackstageController

@implementation CNBackstageController

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization

+ (id)sharedInstance
{
	static CNBackstageController *sharedInstance = nil;
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
        sharedInstance = [[[self class] alloc] init];
	});
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _toggleState                            = CNToggleStateClosed;
        _toggleEdge                             = CNToggleEdgeTop;
        _toggleSize                             = CNToggleSizeHalfScreen;
        _toggleDisplay                          = CNToggleDisplayMain;
        _toggleVisualEffect                     = CNToggleVisualEffectOverlayBlack;
        _toggleAnimationEffect                  = CNToggleAnimationEffectStatic;
        _viewOfFirstPartialDisplaySnapshot      = [[NSView alloc] init];
        _overlayOfFirstPartialDisplaySnapshot   = [[NSView alloc] init];
        _viewOfSecondPartialDisplaySnapshot     = [[NSView alloc] init];
        _overlayOfSecondPartialDisplaySnapshot  = [[NSView alloc] init];
        _applicationView                        = [[NSView alloc] init];
        _toggleAnimationIsRunning               = NO;
        _dockIsHidden                           = NO;
        _delegate                               = nil;
        _applicationViewController              = nil;
        _applicationView                        = nil;
        _backstageViewBackgroundColor           = [NSColor darkGrayColor];
        _overlayAlpha                           = 0.75;
    }
    return self;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public API

- (void)toggleViewState
{
    if (self.toggleAnimationIsRunning == NO) {
        self.toggleAnimationIsRunning = YES;

        [NSApp activateIgnoringOtherApps:YES];

        /// inform the delegate
        [self screen:[self screenOfCurrentToggleDisplay] willToggleOnEdge:self.toggleEdge];

        switch (self.toggleState) {
            case CNToggleStateClosed: [self changeViewStateToOpen]; break;
            case CNToggleStateOpened: [self changeViewStateToClose]; break;
        }
    }
}

- (CNToggleState)currentToggleState
{
    return self.toggleState;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors

- (void)setApplicationViewController:(NSViewController<CNBackstageDelegate> *)applicationViewController
{
    _applicationViewController = applicationViewController;
    self.applicationView = [_applicationViewController view];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive:)
                                                 name:NSApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)setToggleSize:(CNToggleSize)aToggleSize
{
    if(aToggleSize < 0) {
        _toggleSize *= -1;
    }
    if(aToggleSize > NSHeight([self frameOfCurrentToggleDisplay])) {
        _toggleSize = CNToggleSizeHalfScreen;

    } else {
        _toggleSize = aToggleSize;
    }
}

- (CGRect)frameOfCurrentToggleDisplay
{
    return [[self screenOfCurrentToggleDisplay] frame];
}




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Helper

- (void)changeViewStateToOpen
{
    [self initializeApplicationWindow];
    [self buildLayerHierarchy];
    [self createSnapshotOfCurrentToggleDisplay];
    [self hideDock];


    __block NSRect applicationFrame = [self.applicationView frame];
    __block NSRect screenSnapshotFirstFrame = [self.viewOfFirstPartialDisplaySnapshot frame];
    __block NSRect screenSnapshotSecondFrame = [self.viewOfSecondPartialDisplaySnapshot frame];

    switch (self.toggleAnimationEffect) {
        case CNToggleAnimationEffectFade:
            self.applicationView.alphaValue = 0.0;
            break;
        default:
            break;
    }

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        switch (self.toggleAnimationEffect) {
            case CNToggleAnimationEffectStatic:
                break;

            case CNToggleAnimationEffectFade: {
                [[self.applicationView animator] setAlphaValue:1.0];
                break;
            }

            case CNToggleAnimationEffectSlide: {
                switch (self.toggleEdge) {
                    case CNToggleEdgeTop:       applicationFrame.origin.y -= NSHeight(applicationFrame); break;
                    case CNToggleEdgeBottom:    applicationFrame.origin.y += NSHeight(applicationFrame); break;
                    case CNToggleEdgeLeft:      applicationFrame.origin.x += NSWidth(applicationFrame); break;
                    case CNToggleEdgeRight:     applicationFrame.origin.x -= NSWidth(applicationFrame); break;
                    default:
                        break;
                }
                [[self.applicationView animator] setFrame:applicationFrame];
                break;
            }
        }

        // configure the screen snapshot view
        switch (self.toggleEdge) {
            case CNToggleEdgeTop:       screenSnapshotFirstFrame.origin.y -= floor(NSHeight(applicationFrame)); break;
            case CNToggleEdgeBottom:    screenSnapshotFirstFrame.origin.y += floor(NSHeight(applicationFrame)); break;
            case CNToggleEdgeLeft:      screenSnapshotFirstFrame.origin.x += floor(NSWidth(applicationFrame)); break;
            case CNToggleEdgeRight:     screenSnapshotFirstFrame.origin.x -= floor(NSWidth(applicationFrame)); break;

            case CNToggleEdgeSplitHorizontal:
                screenSnapshotFirstFrame.origin.y += floor(NSHeight(applicationFrame)/2);
                screenSnapshotSecondFrame.origin.y -= ceil(NSHeight(applicationFrame)/2)-1;
                break;

            case CNToggleEdgeSplitVertical:
                screenSnapshotFirstFrame.origin.x -= ceil(NSWidth(applicationFrame)/2)-1;
                screenSnapshotSecondFrame.origin.x += ceil(NSWidth(applicationFrame)/2)-1;
                break;
        }

        [self activateVisualEffects];
        [[self.viewOfFirstPartialDisplaySnapshot animator] setFrame:screenSnapshotFirstFrame];
        [[self.viewOfSecondPartialDisplaySnapshot animator] setFrame:screenSnapshotSecondFrame];


    } completionHandler:^{
        self.toggleState = CNToggleStateOpened;
        self.toggleAnimationIsRunning = NO;

        /// inform the delegate
        [self screen:[self screenOfCurrentToggleDisplay] didToggleOnEdge:self.toggleEdge];
    }];
}

- (void)changeViewStateToClose
{
    __block NSRect applicationFrame = [self.applicationView frame];
    __block NSRect screenSnapshotFirstFrame = [self.viewOfFirstPartialDisplaySnapshot frame];
    __block NSRect screenSnapshotSecondFrame = [self.viewOfSecondPartialDisplaySnapshot frame];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        switch (self.toggleAnimationEffect) {
            case CNToggleAnimationEffectStatic:
                break;

            case CNToggleAnimationEffectFade: {
                [[self.applicationView animator] setAlphaValue:0.0];
                break;
            }

            case CNToggleAnimationEffectSlide: {
                switch (self.toggleEdge) {
                    case CNToggleEdgeTop:       applicationFrame.origin.y += floor(NSHeight(applicationFrame)); break;
                    case CNToggleEdgeBottom:    applicationFrame.origin.y -= floor(NSHeight(applicationFrame)); break;
                    case CNToggleEdgeLeft:      applicationFrame.origin.x -= NSWidth(applicationFrame); break;
                    case CNToggleEdgeRight:     applicationFrame.origin.x += NSWidth(applicationFrame); break;
                    default:
                        break;
                }
                [[self.applicationView animator] setFrame:applicationFrame];
                break;
            }
        }

        // animate the snapshot
        switch (self.toggleEdge) {
            case CNToggleEdgeTop:       screenSnapshotFirstFrame.origin.y += floor(NSHeight(applicationFrame)); break;
            case CNToggleEdgeBottom:    screenSnapshotFirstFrame.origin.y -= floor(NSHeight(applicationFrame)); break;
            case CNToggleEdgeLeft:      screenSnapshotFirstFrame.origin.x -= NSWidth(applicationFrame)+1; break;
            case CNToggleEdgeRight:     screenSnapshotFirstFrame.origin.x += NSWidth(applicationFrame)+1; break;

            case CNToggleEdgeSplitHorizontal:
                screenSnapshotFirstFrame.origin.y -= floor(NSHeight(applicationFrame)/2);
                screenSnapshotSecondFrame.origin.y += ceil(NSHeight(applicationFrame)/2)-1;
                break;

            case CNToggleEdgeSplitVertical:
                screenSnapshotFirstFrame.origin.x += floor(NSWidth(applicationFrame)/2);
                screenSnapshotSecondFrame.origin.x -= ceil(NSWidth(applicationFrame)/2)-1;
                break;
        }

        [self deactivateVisualEffects];
        [[self.viewOfFirstPartialDisplaySnapshot animator] setFrame:screenSnapshotFirstFrame];
        [[self.viewOfSecondPartialDisplaySnapshot animator] setFrame:screenSnapshotSecondFrame];


    } completionHandler:^{
        [self showDock];
        [self resignApplicationWindow];

        self.toggleAnimationIsRunning = NO;
        self.toggleState = CNToggleStateClosed;

        /// inform the delegate
        [self screen:[self screenOfCurrentToggleDisplay] didToggleOnEdge:self.toggleEdge];
    }];
}

- (void)activateVisualEffects
{
    switch (self.toggleVisualEffect) {
        case CNToggleVisualEffectOverlayBlack:
            self.overlayOfFirstPartialDisplaySnapshot.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
            [[self.overlayOfFirstPartialDisplaySnapshot animator] setAlphaValue:self.overlayAlpha];
            self.overlayOfSecondPartialDisplaySnapshot.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
            [[self.overlayOfSecondPartialDisplaySnapshot animator] setAlphaValue:self.overlayAlpha];
            break;
        default:
            break;
    }
}

- (void)deactivateVisualEffects
{
    switch (self.toggleVisualEffect) {
        case CNToggleVisualEffectOverlayBlack:
            [[self.overlayOfFirstPartialDisplaySnapshot animator] setAlphaValue:0.0];
            [[self.overlayOfSecondPartialDisplaySnapshot animator] setAlphaValue:0.0];
            break;
        default:
            break;
    }
}

- (NSScreen*)screenOfCurrentToggleDisplay
{
    return [self screenForDisplayWithID:[self displayIDForCurrentToggleDisplay:self.toggleDisplay]];
}

- (CNToggleFrameDeltas)toggleDeltasForFrame:(NSRect)aFrame
{
    CNToggleFrameDeltas frameDeltas = CNMakeToggleFrameDeltas(0, 0);
    switch (self.toggleEdge) {
        case CNToggleEdgeTop:
        case CNToggleEdgeBottom:
        case CNToggleEdgeSplitHorizontal: {
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
        case CNToggleEdgeRight:
        case CNToggleEdgeSplitVertical:  {
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
    }
    return frameDeltas;
}

- (void)initializeApplicationWindow
{
    CGDirectDisplayID displayID = [self displayIDForCurrentToggleDisplay:self.toggleDisplay];
    NSRect windowRect = NSMakeRect(0, 0, CGDisplayPixelsWide(displayID), CGDisplayPixelsHigh(displayID));

    if (self.toggleDisplay == CNToggleDisplayMain) {
        windowRect.size.height -= [self thicknessOfSystemStatusBarForCurrentToggleDisplay];
    }

    NSWindow *controllerWindow = [[NSWindow alloc] initWithContentRect:windowRect
                                                             styleMask:NSBorderlessWindowMask
                                                               backing:NSBackingStoreBuffered
                                                                 defer:NO
                                                                screen:[self screenForDisplayWithID:displayID]];
    [controllerWindow setHasShadow:NO];
    [controllerWindow setDisplaysWhenScreenProfileChanges:YES];
    [controllerWindow setReleasedWhenClosed:NO];
    [controllerWindow setBackgroundColor:self.backstageViewBackgroundColor];
    [controllerWindow setCollectionBehavior:(NSWindowCollectionBehaviorDefault |
                                             NSWindowCollectionBehaviorManaged |
                                             NSWindowCollectionBehaviorFullScreenAuxiliary)];
    [[controllerWindow contentView] setWantsLayer:YES];
    [self setWindow:controllerWindow];
}

- (void)buildLayerHierarchy
{
    NSView *controllerWindowContentView = [[self window] contentView];

    // Application
    self.applicationView.frame = [self frameOfApplicationView];
    [controllerWindowContentView addSubview:self.applicationView];

    // application shadow view
    self.shadowView = [[CNBackstageShadowView alloc] initWithFrame:[self.applicationView bounds]];
    self.shadowView.toggleEdge = self.toggleEdge;
    [self.applicationView addSubview:self.shadowView];

    // Screen Snapshot, First
    [controllerWindowContentView addSubview:self.viewOfFirstPartialDisplaySnapshot];

    // Screen Snapshot Overlay, First
    [self.viewOfFirstPartialDisplaySnapshot addSubview:self.overlayOfFirstPartialDisplaySnapshot];
    self.overlayOfFirstPartialDisplaySnapshot.alphaValue = 0.0;

    if (self.toggleEdge == CNToggleEdgeSplitHorizontal || self.toggleEdge == CNToggleEdgeSplitVertical) {
        [controllerWindowContentView addSubview:self.viewOfSecondPartialDisplaySnapshot];
        [self.viewOfSecondPartialDisplaySnapshot addSubview:self.overlayOfSecondPartialDisplaySnapshot];
        self.overlayOfSecondPartialDisplaySnapshot.alphaValue = 0.0;
    }
}

- (NSRect)frameOfApplicationView
{
    NSRect resultRect = NSZeroRect;
    NSRect windowFrame = [[self window] frame];

    switch (self.toggleEdge) {
        case CNToggleEdgeTop: {
            resultRect.size = NSMakeSize(NSWidth(windowFrame), ceil([self toggleDeltasForFrame:windowFrame].deltaY));
            switch (self.toggleAnimationEffect) {
                case CNToggleAnimationEffectStatic:
                case CNToggleAnimationEffectFade:
                    resultRect.origin.y = NSHeight(windowFrame) - NSHeight(resultRect);
                    break;

                case CNToggleAnimationEffectSlide:
                    resultRect.origin.y = NSHeight(windowFrame);
                    break;
            }
            break;
        }

        case CNToggleEdgeBottom: {
            resultRect.size = NSMakeSize(NSWidth(windowFrame), ceil([self toggleDeltasForFrame:windowFrame].deltaY));
            switch (self.toggleAnimationEffect) {
                case CNToggleAnimationEffectStatic:
                case CNToggleAnimationEffectFade:
                    resultRect.origin.y = 0;
                    break;

                case CNToggleAnimationEffectSlide:
                    resultRect.origin.y = 0 - NSHeight(resultRect);
                    break;
            }
            break;
        }

        case CNToggleEdgeLeft: {
            resultRect.size = NSMakeSize(ceil([self toggleDeltasForFrame:windowFrame].deltaX), NSHeight(windowFrame));
            switch (self.toggleAnimationEffect) {
                case CNToggleAnimationEffectStatic:
                case CNToggleAnimationEffectFade:
                    resultRect.origin.x = 0;
                    break;

                case CNToggleAnimationEffectSlide:
                    resultRect.origin.x = 0 - NSWidth(resultRect);
                    break;
            }
            break;
        }

        case CNToggleEdgeRight: {
            resultRect.size = NSMakeSize(ceil([self toggleDeltasForFrame:windowFrame].deltaX), NSHeight(windowFrame));
            switch (self.toggleAnimationEffect) {
                case CNToggleAnimationEffectStatic:
                case CNToggleAnimationEffectFade:
                    resultRect.origin.x = NSWidth([[self window] frame]) - NSWidth(resultRect);
                    break;

                case CNToggleAnimationEffectSlide:
                    resultRect.origin.x = NSWidth([[self window] frame]);
                    break;
            }
            break;
        }

        case CNToggleEdgeSplitHorizontal:
            resultRect.size = NSMakeSize(NSWidth(windowFrame), ceil([self toggleDeltasForFrame:windowFrame].deltaY));
            resultRect.origin.y = floor((NSHeight(windowFrame) - NSHeight(resultRect)) / 2);
            break;

        case CNToggleEdgeSplitVertical:
            resultRect.size = NSMakeSize(ceil([self toggleDeltasForFrame:windowFrame].deltaX), NSHeight(windowFrame));
            resultRect.origin.x = floor((NSWidth(windowFrame) - NSWidth(resultRect)) / 2);
            break;
    }
    CNLogForRect(resultRect);
    return resultRect;
}

- (void)createSnapshotOfCurrentToggleDisplay
{
    CGDirectDisplayID displayID = [self displayIDForCurrentToggleDisplay:self.toggleDisplay];
    CGImageRef snapshotRef = [self snapshotOfDisplayWithID:displayID];
    NSRect contentViewBounds = [[[self window] contentView] bounds];

    switch (self.toggleEdge) {
        case CNToggleEdgeTop:
        case CNToggleEdgeBottom:
        case CNToggleEdgeLeft:
        case CNToggleEdgeRight: {
            self.viewOfFirstPartialDisplaySnapshot.frame = contentViewBounds;
            self.viewOfFirstPartialDisplaySnapshot.layer.contents = (__bridge id)(snapshotRef);

            self.overlayOfFirstPartialDisplaySnapshot.frame = contentViewBounds;
            break;
        }

        case CNToggleEdgeSplitHorizontal: {
            self.viewOfFirstPartialDisplaySnapshot.frame = NSMakeRect(NSMinX(contentViewBounds), NSMaxY(contentViewBounds) - floor(NSHeight(contentViewBounds)/2), NSWidth(contentViewBounds),floor( NSHeight(contentViewBounds)/2));
            CGImageRef snapshotFirstSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(0, 0, NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2)));
            self.overlayOfFirstPartialDisplaySnapshot.frame = self.viewOfFirstPartialDisplaySnapshot.bounds;

            self.viewOfSecondPartialDisplaySnapshot.frame = NSMakeRect(NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2));
            CGImageRef snapshotSecondSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(0, floor(NSHeight(contentViewBounds)/2)+1, NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2)));
            self.overlayOfSecondPartialDisplaySnapshot.frame = self.viewOfSecondPartialDisplaySnapshot.bounds;

            self.viewOfFirstPartialDisplaySnapshot.layer.contents = (__bridge id)(snapshotFirstSplit);
            self.viewOfSecondPartialDisplaySnapshot.layer.contents = (__bridge id)(snapshotSecondSplit);
            CGImageRelease(snapshotFirstSplit);
            CGImageRelease(snapshotSecondSplit);
            break;
        }

        case CNToggleEdgeSplitVertical:
            self.viewOfFirstPartialDisplaySnapshot.frame = NSMakeRect(0, 0, NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds));
            CGImageRef snapshotFirstSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(0, 0, NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds)));
            self.overlayOfFirstPartialDisplaySnapshot.frame = self.viewOfFirstPartialDisplaySnapshot.bounds;

            self.viewOfSecondPartialDisplaySnapshot.frame = NSMakeRect(NSWidth(contentViewBounds)/2 + 1, 0, NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds));
            CGImageRef snapshotSecondSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(NSWidth(contentViewBounds)/2 + 1, 0, NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds)));
            self.overlayOfSecondPartialDisplaySnapshot.frame = self.viewOfSecondPartialDisplaySnapshot.bounds;

            self.viewOfFirstPartialDisplaySnapshot.layer.contents = (__bridge id)(snapshotFirstSplit);
            self.viewOfSecondPartialDisplaySnapshot.layer.contents = (__bridge id)(snapshotSecondSplit);
            CGImageRelease(snapshotFirstSplit);
            CGImageRelease(snapshotSecondSplit);
            break;
    }
    CGImageRelease(snapshotRef);

    [self showWindow:nil];
}

- (void)resignApplicationWindow
{
    [self.shadowView removeFromSuperview];
    [self.overlayOfFirstPartialDisplaySnapshot removeFromSuperview];
    [self.viewOfFirstPartialDisplaySnapshot removeFromSuperview];
    [self.overlayOfSecondPartialDisplaySnapshot removeFromSuperview];
    [self.viewOfSecondPartialDisplaySnapshot removeFromSuperview];
    self.applicationView.alphaValue = 1.0;

    self.shadowView = [[CNBackstageShadowView alloc] init];
    self.viewOfFirstPartialDisplaySnapshot = [[NSView alloc] init];
    self.overlayOfFirstPartialDisplaySnapshot = [[NSView alloc] init];
    self.viewOfSecondPartialDisplaySnapshot = [[NSView alloc] init];
    self.overlayOfSecondPartialDisplaySnapshot = [[NSView alloc] init];
    [self.window close];
    self.window = [NSWindow new];
}

- (int)thicknessOfSystemStatusBarForCurrentToggleDisplay
{
    return ([self displayIDForCurrentToggleDisplay:self.toggleDisplay] == CGMainDisplayID() ? [[NSStatusBar systemStatusBar] thickness] : 0);
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
        [[NSApplication sharedApplication] setPresentationOptions:NSApplicationPresentationDefault];
        self.dockIsHidden = NO;
    }
}

- (void)hideDock
{
    if ([[self screenOfCurrentToggleDisplay] containsDock]) {
        [[NSApplication sharedApplication] setPresentationOptions:NSApplicationPresentationHideDock];
        self.dockIsHidden = YES;
    }
}

- (CGImageRef)snapshotOfDisplayWithID:(CGDirectDisplayID)displayID
{
    return CGDisplayCreateImageForRect(displayID, CGRectMake(0, 0 + [self thicknessOfSystemStatusBarForCurrentToggleDisplay],
                                                             NSWidth(self.frameOfCurrentToggleDisplay),
                                                             NSHeight(self.frameOfCurrentToggleDisplay) - [self thicknessOfSystemStatusBarForCurrentToggleDisplay]));
}

- (CGDirectDisplayID)displayIDForCurrentToggleDisplay:(CNToggleDisplay)aToggleDisplay
{
    uint32_t MAX_TOGGLE_DISPLAYS = 4;   // number of supported displays
    uint32_t displayCount;
    CGDirectDisplayID toggleDisplays[MAX_TOGGLE_DISPLAYS];
    CGGetOnlineDisplayList(MAX_TOGGLE_DISPLAYS, toggleDisplays, &displayCount);

    return (aToggleDisplay > displayCount ? toggleDisplays[0]: toggleDisplays[aToggleDisplay]);
}

- (NSScreen*)screenForDisplayWithID:(CGDirectDisplayID)displayID
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
#pragma mark - NSResponder

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!NSPointInRect([theEvent locationInWindow], [self.applicationView frame])) {
        [self changeViewStateToClose];
    }
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    if (!NSPointInRect([theEvent locationInWindow], [self.applicationView frame])) {
        [self changeViewStateToClose];
    }
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
    if (!NSPointInRect([theEvent locationInWindow], [self.applicationView frame])) {
        [self changeViewStateToClose];
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Notifications

- (void)willResignActive:(NSNotification *)notification
{
    if (self.currentToggleState == CNToggleStateOpened) {
        [self changeViewStateToClose];
    }
}




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstage Delegate Callbacks

- (void)screen:(NSScreen *)toggleScreen willToggleOnEdge:(CNToggleEdge)toggleEdge
{
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate screen:[self screenOfCurrentToggleDisplay] willToggleOnEdge:self.toggleEdge];
    }
}

- (void)screen:(NSScreen *)toggleScreen didToggleOnEdge:(CNToggleEdge)toggleEdge
{
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate screen:[self screenOfCurrentToggleDisplay] didToggleOnEdge:self.toggleEdge];
    }
}

@end





/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstageShadowView

static NSColor *startColor, *middleColor, *endColor, *darkLineColor, *lightLineColor;
static CGFloat shadowWidth = 8.0;

@interface CNBackstageShadowView ()
@end
@implementation CNBackstageShadowView

+ (void)initialize
{
    startColor = [[NSColor blackColor] colorWithAlphaComponent:0.55];
    middleColor = [[NSColor blackColor] colorWithAlphaComponent:0.32];
    endColor = [[NSColor blackColor] colorWithAlphaComponent:0.001];
    darkLineColor = [NSColor colorWithCalibratedRed:0.119 green:0.120 blue:0.120 alpha:1.000];
    lightLineColor = [NSColor colorWithDeviceRed:0.711 green:0.718 blue:0.718 alpha:1.000];
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
        case CNToggleEdgeTop: {
            NSRect lineRect = NSMakeRect(NSMinX(dirtyRect), floor(NSMinY(dirtyRect)), NSWidth(dirtyRect), 1);
            NSBezierPath *linePath = [NSBezierPath bezierPathWithRect:lineRect];
            [lightLineColor setFill];
            [linePath fill];

            gradientRect = NSMakeRect(NSMinX(dirtyRect), NSHeight(dirtyRect)-shadowWidth, NSWidth(dirtyRect), shadowWidth);
            angle = -90;
            break;
        }
        case CNToggleEdgeRight: {
            NSRect lineRect = NSMakeRect(NSMinX(dirtyRect), NSMinY(dirtyRect), 1, NSHeight(dirtyRect));
            NSBezierPath *linePath = [NSBezierPath bezierPathWithRect:lineRect];
            [darkLineColor setFill];
            [linePath fill];

            gradientRect = NSMakeRect(NSMinX(dirtyRect), NSMinY(dirtyRect), shadowWidth, NSHeight(dirtyRect));
            angle = 0;
            break;
        }
        case CNToggleEdgeBottom: {
            NSRect lineRect = NSMakeRect(NSMinX(dirtyRect), ceil(NSMaxY(dirtyRect))-1, NSWidth(dirtyRect), 1);
            NSBezierPath *linePath = [NSBezierPath bezierPathWithRect:lineRect];
            [darkLineColor setFill];
            [linePath fill];

            gradientRect = NSMakeRect(NSMinX(dirtyRect), NSHeight(dirtyRect)-shadowWidth, NSWidth(dirtyRect), shadowWidth);
            angle = -90;
            break;
        }
        case CNToggleEdgeLeft: {
            NSRect lineRect = NSMakeRect(floor(NSWidth(dirtyRect))-1, NSMinY(dirtyRect), 1, NSHeight(dirtyRect));
            NSBezierPath *linePath = [NSBezierPath bezierPathWithRect:lineRect];
            [lightLineColor setFill];
            [linePath fill];

            gradientRect = NSMakeRect(NSMinX(dirtyRect), NSMinY(dirtyRect), shadowWidth, NSHeight(dirtyRect));
            angle = 0;
            break;
        }

        case CNToggleEdgeSplitHorizontal: {
            NSRect lineTopRect = NSMakeRect(NSMinX(dirtyRect), floor(NSMaxY(dirtyRect))-1, NSWidth(dirtyRect), 1);
            NSBezierPath *lineTopPath = [NSBezierPath bezierPathWithRect:lineTopRect];
            [darkLineColor setFill];
            [lineTopPath fill];

            NSRect lineBottomRect = NSMakeRect(NSMinX(dirtyRect), ceil(NSMinY(dirtyRect))+1, NSWidth(dirtyRect), 1);
            NSBezierPath *lineBottomPath = [NSBezierPath bezierPathWithRect:lineBottomRect];
            [lightLineColor setFill];
            [lineBottomPath fill];

            gradientRect = NSMakeRect(NSMinX(dirtyRect), NSHeight(dirtyRect)-shadowWidth, NSWidth(dirtyRect), shadowWidth);
            angle = -90;
            break;
        }

        case CNToggleEdgeSplitVertical: {
            NSRect lineLeftRect = NSMakeRect(ceil(NSMinX(dirtyRect))+1, NSMinY(dirtyRect), 1, NSHeight(dirtyRect));
            NSBezierPath *lineTopPath = [NSBezierPath bezierPathWithRect:lineLeftRect];
            [darkLineColor setFill];
            [lineTopPath fill];

            NSRect lineRightRect = NSMakeRect(NSMaxX(dirtyRect)-1, NSMinY(dirtyRect), 1, NSHeight(dirtyRect));
            NSBezierPath *lineBottomPath = [NSBezierPath bezierPathWithRect:lineRightRect];
            [lightLineColor setFill];
            [lineBottomPath fill];

            gradientRect = NSMakeRect(ceil(NSMinX(dirtyRect))+1, NSMinY(dirtyRect), shadowWidth, NSHeight(dirtyRect));
            angle = 0;
            break;
        }
    }
    NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations: startColor, 0.0, middleColor, 0.20, endColor, 1.0, nil];
    NSBezierPath *gradienPath = [NSBezierPath bezierPathWithRect:gradientRect];
    [gradient drawInBezierPath:gradienPath angle:angle];
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    // pass-through all events
    for (NSView *subView in [self subviews]) {
        if (![subView isHidden] && [subView hitTest:aPoint])
            return subView;
    }
    return nil;
}

@end
