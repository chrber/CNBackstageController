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
#import "CNBackstageShadowView.h"



static CGFloat kAnimationDuration = 0.25;

/// NSUserDefaults keys
NSString *CNToggleEdgePreferencesKey = @"CNToggleEdge";
NSString *CNToggleSizePreferencesKey = @"CNToggleSize";
NSString *CNToggleSizeWidthPreferencesKey = @"CNToggleSizeWidth";
NSString *CNToggleSizeHeightPreferencesKey = @"CNToggleSizeHeight";
NSString *CNToggleDisplayPreferencesKey = @"CNToggleDisplay";
NSString *CNToggleVisualEffectPreferencesKey = @"CNToggleVisualEffect";
NSString *CNToggleAnimationEffectPreferencesKey = @"CNToggleAnimationEffect";
NSString *CNToggleAlphaValuePreferencesKey = @"CNToggleAlphaValue";
NSString *CNToggleUseShadowsPreferencesKey = @"CNToggleUseShadows";


/// Notifications
NSString *CNBackstageControllerWillExpandOnScreenNotification = @"CNBackstageControllerWillExpandOnScreen";
NSString *CNBackstageControllerDidExpandOnScreenNotification = @"CNBackstageControllerDidExpandOnScreen";
NSString *CNBackstageControllerWillCollapseOnScreenNotification = @"CNBackstageControllerWillCollapseOnScreen";
NSString *CNBackstageControllerDidCollapseOnScreenNotification = @"CNBackstageControllerDidCollapseOnScreen";
NSString *CNBackstageControllerWillDragOnScreenNotification = @"CNBackstageControllerWillDragOnScreen";
NSString *CNBackstageControllerDidDragOnScreenNotification = @"CNBackstageControllerDidDragOnScreen";


/// Keys that are used for the userInfo dictionary in the notifications from above
NSString *CNToggleScreenUserInfoKey = @"toggleScreen";
NSString *CNToggleEdgeUserInfoKey = @"toggleEdge";


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Convenience Functions

CNToggleFrameDeltas CNMakeToggleFrameDeltas(CGFloat deltaX, CGFloat deltaY) {
    CNToggleFrameDeltas frameDeltas;
    frameDeltas.deltaX = deltaX;
    frameDeltas.deltaY = deltaY;
    return frameDeltas;
}

CNToggleSize CNMakeToggleSize(NSUInteger aWidth, NSUInteger aHeight) {
    CNToggleSize toggleSize;
    toggleSize.width = aWidth;
    toggleSize.height = aHeight;
    return toggleSize;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstageController Extension

@interface CNBackstageController() {
    NSApplicationPresentationOptions presentationOptionsBackup;
    NSNotificationCenter *notifCenter;
    NSUserDefaults *defaults;
    NSView *applicationView;
    NSView *applicationFirstCoverView;
    NSView *applicationFirstCoverOverlayView;
    NSView *applicationSecondCoverView;
    NSView *applicationSecondCoverOverlayView;
    CNBackstageShadowView *shadowView;
    NSPoint initialDraggingPoint;
    NSPoint initialFirstCoverOrigin;
    NSPoint initialSecondCoverOrigin;
    NSRect initialApplicationViewFrame;
    CNToggleState toggleState;
    BOOL dockIsHidden;
    BOOL toggleAnimationIsRunning;
    BOOL applicationCoverIsDragging;
    CIFilter *gaussianBlurFilter;
    CNToggleSize _toggleSize;
}
@property (readonly) NSRect currentToggleDisplayFrame;

- (void)expandUsingCompletionHandler:(void(^)(void))completionHandler;
- (void)collapseUsingCompletionHandler:(void(^)(void))completionHandler;
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
- (void)restorePresentationOptions;
- (void)setupPresentationOptions;
- (CGImageRef)snapshotOfDisplayWithID:(CGDirectDisplayID)displayID;
- (CGDirectDisplayID)displayIDForCurrentToggleDisplay:(CNToggleDisplay)aToggleDisplay;
- (NSScreen*)screenForDisplayWithID:(CGDirectDisplayID)displayID;
- (void)dragCoverageUsingAnchorPoint:(NSPoint)location;
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
        /// properties of public API
        _delegate                               = nil;
        _toggleEdge                             = CNToggleEdgeTop;
        _toggleSize                             = CNMakeToggleSize(CNToggleSizeQuarterScreen, CNToggleSizeQuarterScreen);
        _toggleDisplay                          = CNToggleDisplayMain;
        _toggleVisualEffect                     = CNToggleVisualEffectOverlayBlack;
        _toggleAnimationEffect                  = CNToggleAnimationEffectStatic;
        _applicationViewController              = nil;
        _backgroundColor                        = [NSColor darkGrayColor];
        _overlayAlpha                           = 0.75;
        _resizingAllowed                        = YES;
        _applicationViewMinSize                 = NSMakeSize(200.0f, 120.0f);
        _useShadows                             = YES;

        /// private properties
        notifCenter                             = [NSNotificationCenter defaultCenter];
        defaults                                = [NSUserDefaults standardUserDefaults];
        applicationCoverIsDragging              = NO;
        toggleAnimationIsRunning                = NO;
        dockIsHidden                            = NO;
        applicationView                         = [[NSView alloc] init];
        applicationFirstCoverView               = [[NSView alloc] init];
        applicationFirstCoverOverlayView        = [[NSView alloc] init];
        applicationSecondCoverView              = [[NSView alloc] init];
        applicationSecondCoverOverlayView       = [[NSView alloc] init];
        shadowView                              = [[CNBackstageShadowView alloc] init];
        initialDraggingPoint                    = NSZeroPoint;
        initialFirstCoverOrigin                 = NSZeroPoint;
        initialSecondCoverOrigin                = NSZeroPoint;
        initialApplicationViewFrame             = NSZeroRect;
        toggleState                             = CNToggleStateCollapsed;
    }
    return self;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - API

- (void)toggleViewState
{
    NSAssert(self.applicationViewController != nil, @"\n\nThe applicationViewController property must be NOT nil!\nAfter you created your CNBackstageController instance you have to set applicationViewController property.\n\n");
    
    switch (toggleState) {
        case CNToggleStateCollapsed: [self expand]; break;
        case CNToggleStateExpanded: [self collapse]; break;
    }
}

- (void)expand
{
    if (toggleAnimationIsRunning == NO) {
        toggleAnimationIsRunning = YES;

        [NSApp activateIgnoringOtherApps:YES];

        /// inform the delegate
        [self backstageController:self willExpandOnScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];

        [self expandUsingCompletionHandler:^{
            /// inform the delegate
            [self backstageController:self didExpandOnScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];
            toggleAnimationIsRunning = NO;
        }];
    }
}

- (void)collapse
{
    if (toggleAnimationIsRunning == NO) {
        toggleAnimationIsRunning = YES;

        /// inform the delegate
        [self backstageController:self willCollapseOnScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];

        [self collapseUsingCompletionHandler:^{
            /// inform the delegate
            [self backstageController:self didCollapseOnScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];
            toggleAnimationIsRunning = NO;
        }];
    }
}

- (CNToggleState)currentViewState
{
    return toggleState;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors

- (void)setApplicationViewController:(NSViewController<CNBackstageDelegate> *)applicationViewController
{
    _applicationViewController = applicationViewController;
    applicationView = [_applicationViewController view];
    self.delegate = _applicationViewController;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive:)
                                                 name:NSApplicationWillResignActiveNotification
                                               object:nil];
}

- (CNToggleSize)toggleSize
{
    return _toggleSize;
}

- (void)setToggleSize:(CNToggleSize)aToggleSize
{
    NSUInteger width = 0, height = 0;

    switch (aToggleSize.width) {
        case CNToggleSizeQuarterScreen:
        case CNToggleSizeHalfScreen:
        case CNToggleSizeOneThirdScreen:
        case CNToggleSizeTwoThirdsScreen:
        case CNToggleSizeThreeQuarterScreen:
            width = aToggleSize.width;
            break;

        default: {
            switch (self.toggleEdge) {
                case CNToggleEdgeLeft:
                case CNToggleEdgeRight:
                case CNToggleEdgeSplitHorizontal: {
                    CGFloat windowWidth = NSWidth([[self window] frame]);
                    if (aToggleSize.width <= windowWidth) {
                        width = aToggleSize.width;
                    }

                    else if (aToggleSize.width <= self.applicationViewMinSize.width) {
                        /// fallback
                        width = self.applicationViewMinSize.width;

                    } else {
                        /// fallback
                        width = CNToggleSizeQuarterScreen;
                    }
                    break;
                }
                default: break;
            }
            break;
        }
    }

    switch (aToggleSize.height) {
        case CNToggleSizeQuarterScreen:
        case CNToggleSizeHalfScreen:
        case CNToggleSizeOneThirdScreen:
        case CNToggleSizeTwoThirdsScreen:
        case CNToggleSizeThreeQuarterScreen:
            height = aToggleSize.height;
            break;

        default: {
            switch (self.toggleEdge) {
                case CNToggleEdgeTop:
                case CNToggleEdgeBottom:
                case CNToggleEdgeSplitVertical: {
                    CGFloat windowHeight = NSHeight([[self window] frame]);
                    if (aToggleSize.height <= windowHeight && aToggleSize.height >= self.applicationViewMinSize.height) {
                        height = aToggleSize.height;
                    }

                    else if (aToggleSize.height <= self.applicationViewMinSize.height) {
                        height = self.applicationViewMinSize.height;

                    } else {
                        /// fallback
                        height = CNToggleSizeQuarterScreen;
                    }
                    break;
                }
                default: break;
            }
            break;
        }
    }

    _toggleSize = CNMakeToggleSize(width, height);
}

- (CGRect)currentToggleDisplayFrame
{
    return [[self screenOfCurrentToggleDisplay] frame];
}




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Helper

- (void)expandUsingCompletionHandler:(void(^)(void))completionHandler
{
    [self initializeApplicationWindow];
    [self buildLayerHierarchy];
    [self createSnapshotOfCurrentToggleDisplay];
    [self setupPresentationOptions];


    __block NSRect applicationFrame = [applicationView frame];
    __block NSRect screenSnapshotFirstFrame = [applicationFirstCoverView frame];
    __block NSRect screenSnapshotSecondFrame = [applicationSecondCoverView frame];

    switch (self.toggleAnimationEffect) {
        case CNToggleAnimationEffectFade:
            applicationView.alphaValue = 0.0; break;
        default:
            break;
    }

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        switch (self.toggleAnimationEffect) {
            case CNToggleAnimationEffectStatic:
                break;

            case CNToggleAnimationEffectFade:
                [[applicationView animator] setAlphaValue:1.0];
                break;

            case CNToggleAnimationEffectSlide: {
                switch (self.toggleEdge) {
                    case CNToggleEdgeTop:       applicationFrame.origin.y -= ceil(NSHeight(applicationFrame)); break;
                    case CNToggleEdgeBottom:    applicationFrame.origin.y += ceil(NSHeight(applicationFrame)); break;
                    case CNToggleEdgeLeft:      applicationFrame.origin.x += ceil(NSHeight(applicationFrame)); break;
                    case CNToggleEdgeRight:     applicationFrame.origin.x -= ceil(NSWidth(applicationFrame)); break;
                    default:
                        break;
                }
                [[applicationView animator] setFrame:applicationFrame];
                break;
            }
        }

        // configure the screen snapshot view
        switch (self.toggleEdge) {
            case CNToggleEdgeTop:       screenSnapshotFirstFrame.origin.y -= ceil(NSHeight(applicationFrame)); break;
            case CNToggleEdgeBottom:    screenSnapshotFirstFrame.origin.y += ceil(NSHeight(applicationFrame)); break;
            case CNToggleEdgeLeft:      screenSnapshotFirstFrame.origin.x += ceil(NSWidth(applicationFrame)); break;
            case CNToggleEdgeRight:     screenSnapshotFirstFrame.origin.x -= ceil(NSWidth(applicationFrame)); break;

            case CNToggleEdgeSplitHorizontal:
                screenSnapshotFirstFrame.origin.x -= ceil(NSWidth(applicationFrame)/2)-1;
                screenSnapshotSecondFrame.origin.x += ceil(NSWidth(applicationFrame)/2)-1;
                break;

            case CNToggleEdgeSplitVertical:
                screenSnapshotFirstFrame.origin.y += ceil(NSHeight(applicationFrame)/2)-1;
                screenSnapshotSecondFrame.origin.y -= ceil(NSHeight(applicationFrame)/2)-1;
                break;
        }

        [self activateVisualEffects];
        [[applicationFirstCoverView animator] setFrame:screenSnapshotFirstFrame];
        [[applicationSecondCoverView animator] setFrame:screenSnapshotSecondFrame];


    } completionHandler:^{
        toggleState = CNToggleStateExpanded;
        toggleAnimationIsRunning = NO;

        completionHandler();
    }];
}

- (void)collapseUsingCompletionHandler:(void(^)(void))completionHandler
{
    __block NSRect applicationFrame = [applicationView frame];
    __block NSRect screenSnapshotFirstFrame = [applicationFirstCoverView frame];
    __block NSRect screenSnapshotSecondFrame = [applicationSecondCoverView frame];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        switch (self.toggleAnimationEffect) {
            case CNToggleAnimationEffectStatic:
                break;

            case CNToggleAnimationEffectFade:
                [[applicationView animator] setAlphaValue:0.0];
                break;

            case CNToggleAnimationEffectSlide: {
                switch (self.toggleEdge) {
                    case CNToggleEdgeTop:       applicationFrame.origin.y += ceil(NSHeight(applicationFrame)); break;
                    case CNToggleEdgeBottom:    applicationFrame.origin.y -= ceil(NSHeight(applicationFrame)); break;
                    case CNToggleEdgeLeft:      applicationFrame.origin.x -= NSWidth(applicationFrame); break;
                    case CNToggleEdgeRight:     applicationFrame.origin.x += NSWidth(applicationFrame); break;
                    default:
                        break;
                }
                [[applicationView animator] setFrame:applicationFrame];
                break;
            }
        }

        // animate the snapshot
        switch (self.toggleEdge) {
            case CNToggleEdgeTop:       screenSnapshotFirstFrame.origin.y += ceil(NSHeight(applicationFrame)); break;
            case CNToggleEdgeBottom:    screenSnapshotFirstFrame.origin.y -= ceil(NSHeight(applicationFrame)); break;
            case CNToggleEdgeLeft:      screenSnapshotFirstFrame.origin.x -= ceil(NSWidth(applicationFrame)); break;
            case CNToggleEdgeRight:     screenSnapshotFirstFrame.origin.x += ceil(NSWidth(applicationFrame)); break;

            case CNToggleEdgeSplitHorizontal:
                screenSnapshotFirstFrame.origin.x += ceil(NSWidth(applicationFrame)/2)-1;
                screenSnapshotSecondFrame.origin.x -= ceil(NSWidth(applicationFrame)/2)-1;
                break;

            case CNToggleEdgeSplitVertical:
                screenSnapshotFirstFrame.origin.y -= ceil(NSHeight(applicationFrame)/2)-1;
                screenSnapshotSecondFrame.origin.y += ceil(NSHeight(applicationFrame)/2)-1;
                break;
        }

        [self deactivateVisualEffects];
        [[applicationFirstCoverView animator] setFrame:screenSnapshotFirstFrame];
        [[applicationSecondCoverView animator] setFrame:screenSnapshotSecondFrame];


    } completionHandler:^{
        [applicationFirstCoverOverlayView.layer setFilters:nil];
        [applicationSecondCoverOverlayView.layer setFilters:nil];
        [self restorePresentationOptions];
        [self resignApplicationWindow];

        toggleAnimationIsRunning = NO;
        toggleState = CNToggleStateCollapsed;

        completionHandler();
    }];
}

- (void)activateVisualEffects
{
    if (self.toggleVisualEffect == 0)
        return;

    if (self.toggleVisualEffect & CNToggleVisualEffectOverlayBlack) {
        applicationFirstCoverOverlayView.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
        [[applicationFirstCoverOverlayView animator] setAlphaValue:self.overlayAlpha];
        applicationSecondCoverOverlayView.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
        [[applicationSecondCoverOverlayView animator] setAlphaValue:self.overlayAlpha];
    }

    if (self.toggleVisualEffect & CNToggleVisualEffectGaussianBlur) {
        gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [gaussianBlurFilter setDefaults];
        [gaussianBlurFilter setValue:[NSNumber numberWithFloat:2] forKey:@"inputRadius"];
        [applicationFirstCoverOverlayView.layer setMasksToBounds:YES];
        [applicationSecondCoverOverlayView.layer setMasksToBounds:YES];
        [applicationFirstCoverOverlayView.layer setBackgroundFilters:@[gaussianBlurFilter]];
        [applicationSecondCoverOverlayView.layer setBackgroundFilters:@[gaussianBlurFilter]];
    }
}

- (void)deactivateVisualEffects
{
    if (self.toggleVisualEffect == 0)
        return;

    if (self.toggleVisualEffect & CNToggleVisualEffectOverlayBlack) {
        [[applicationFirstCoverOverlayView animator] setAlphaValue:0.0];
        [[applicationSecondCoverOverlayView animator] setAlphaValue:0.0];
    }

    if (self.toggleVisualEffect & CNToggleVisualEffectGaussianBlur) {
        [gaussianBlurFilter setValue:[NSNumber numberWithFloat:0] forKey:@"inputRadius"];
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
        case CNToggleEdgeSplitVertical: {
            switch (self.toggleSize.height) {
                case CNToggleSizeHalfScreen:
                case CNToggleSizeQuarterScreen:
                case CNToggleSizeThreeQuarterScreen:
                case CNToggleSizeOneThirdScreen:
                case CNToggleSizeTwoThirdsScreen:
                    frameDeltas.deltaY = [self valueForToggleSize:self.toggleSize.height frameSize:NSHeight(aFrame)];
                    break;
                default:
                    frameDeltas.deltaY = self.toggleSize.height;
                    break;
            }
            break;
        }
        case CNToggleEdgeLeft:
        case CNToggleEdgeRight:
        case CNToggleEdgeSplitHorizontal:  {
            switch (self.toggleSize.width) {
                case CNToggleSizeHalfScreen:
                case CNToggleSizeQuarterScreen:
                case CNToggleSizeThreeQuarterScreen:
                case CNToggleSizeOneThirdScreen:
                case CNToggleSizeTwoThirdsScreen:
                    frameDeltas.deltaX = [self valueForToggleSize:self.toggleSize.width frameSize:NSWidth(aFrame)];
                    break;
                default:
                    frameDeltas.deltaX = self.toggleSize.width;
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
    [controllerWindow setReleasedWhenClosed:YES];
    [controllerWindow setBackgroundColor:self.backgroundColor];
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
    applicationView.frame = [self frameOfApplicationView];
    [controllerWindowContentView addSubview:applicationView];

    // application shadow view
    shadowView = [[CNBackstageShadowView alloc] initWithFrame:[applicationView bounds]];
    shadowView.toggleEdge = self.toggleEdge;
    shadowView.useShadows = self.useShadows;
    [shadowView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [applicationView addSubview:shadowView];
    [applicationView setAutoresizesSubviews:YES];

    // Screen Snapshot, First
    [controllerWindowContentView addSubview:applicationFirstCoverView];

    // Screen Snapshot Overlay, First
    [applicationFirstCoverView addSubview:applicationFirstCoverOverlayView];
    applicationFirstCoverOverlayView.alphaValue = 0.0;

    if (self.toggleEdge == CNToggleEdgeSplitHorizontal || self.toggleEdge == CNToggleEdgeSplitVertical) {
        [controllerWindowContentView addSubview:applicationSecondCoverView];
        [applicationSecondCoverView addSubview:applicationSecondCoverOverlayView];
        applicationSecondCoverOverlayView.alphaValue = 0.0;
    }

    if (self.isResizingAllowed) {
        NSTrackingArea *firstTrackingArea = [[NSTrackingArea alloc] initWithRect:applicationFirstCoverView.frame
                                                                         options:NSTrackingMouseEnteredAndExited | NSTrackingCursorUpdate | NSTrackingActiveInKeyWindow
                                                                           owner:self
                                                                        userInfo:nil];
        [applicationFirstCoverView addTrackingArea:firstTrackingArea];

        NSTrackingArea *secondTrackingArea = [[NSTrackingArea alloc] initWithRect:applicationSecondCoverView.frame
                                                                         options:NSTrackingMouseEnteredAndExited | NSTrackingCursorUpdate | NSTrackingActiveInKeyWindow
                                                                           owner:self
                                                                        userInfo:nil];
        [applicationSecondCoverView addTrackingArea:secondTrackingArea];
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
            resultRect.size = NSMakeSize(ceil([self toggleDeltasForFrame:windowFrame].deltaX), NSHeight(windowFrame));
            resultRect.origin.x = floor((NSWidth(windowFrame) - NSWidth(resultRect)) / 2);
            break;

        case CNToggleEdgeSplitVertical:
            resultRect.size = NSMakeSize(NSWidth(windowFrame), ceil([self toggleDeltasForFrame:windowFrame].deltaY));
            resultRect.origin.y = floor((NSHeight(windowFrame) - NSHeight(resultRect)) / 2);
            break;
    }
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
            applicationFirstCoverView.frame = contentViewBounds;
            applicationFirstCoverView.layer.contents = (__bridge id)(snapshotRef);

            applicationFirstCoverOverlayView.frame = contentViewBounds;
            break;
        }

        case CNToggleEdgeSplitHorizontal: {
            applicationFirstCoverView.frame = NSMakeRect(NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds));
            CGImageRef snapshotFirstSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds)));
            applicationFirstCoverOverlayView.frame = applicationFirstCoverView.bounds;

            applicationSecondCoverView.frame = NSMakeRect(NSWidth(contentViewBounds)/2 + 1, NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds));
            CGImageRef snapshotSecondSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(NSWidth(contentViewBounds)/2, NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds)));
            applicationSecondCoverOverlayView.frame = applicationSecondCoverView.bounds;

            applicationFirstCoverView.layer.contents = (__bridge id)(snapshotFirstSplit);
            applicationSecondCoverView.layer.contents = (__bridge id)(snapshotSecondSplit);
            CGImageRelease(snapshotFirstSplit);
            CGImageRelease(snapshotSecondSplit);
            break;
        }

        case CNToggleEdgeSplitVertical:
            applicationFirstCoverView.frame = NSMakeRect(NSMinX(contentViewBounds), NSMaxY(contentViewBounds) - floor(NSHeight(contentViewBounds)/2), NSWidth(contentViewBounds),floor( NSHeight(contentViewBounds)/2));
            CGImageRef snapshotFirstSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2)));
            applicationFirstCoverOverlayView.frame = applicationFirstCoverView.bounds;

            applicationSecondCoverView.frame = NSMakeRect(NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2));
            CGImageRef snapshotSecondSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(NSMinX(contentViewBounds), floor(NSHeight(contentViewBounds)/2), NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2)));
            applicationSecondCoverOverlayView.frame = applicationSecondCoverView.bounds;

            applicationFirstCoverView.layer.contents = (__bridge id)(snapshotFirstSplit);
            applicationSecondCoverView.layer.contents = (__bridge id)(snapshotSecondSplit);
            CGImageRelease(snapshotFirstSplit);
            CGImageRelease(snapshotSecondSplit);
            break;
    }
    CGImageRelease(snapshotRef);
}

- (void)resignApplicationWindow
{
    self.window.alphaValue = 0.0;
    
    [shadowView removeFromSuperview];
    [applicationFirstCoverOverlayView removeFromSuperview];
    [applicationFirstCoverView removeFromSuperview];
    [applicationSecondCoverOverlayView removeFromSuperview];
    [applicationSecondCoverView removeFromSuperview];
    applicationView.alphaValue = 1.0;

    shadowView = [[CNBackstageShadowView alloc] init];
    applicationFirstCoverView = [[NSView alloc] init];
    applicationFirstCoverOverlayView = [[NSView alloc] init];
    applicationSecondCoverView = [[NSView alloc] init];
    applicationSecondCoverOverlayView = [[NSView alloc] init];
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

- (void)restorePresentationOptions
{
    if (dockIsHidden) {
        [NSApp setPresentationOptions:presentationOptionsBackup];
        dockIsHidden = NO;
    }
}

- (void)setupPresentationOptions
{
    [self showWindow:nil];
    presentationOptionsBackup = [NSApp currentSystemPresentationOptions];
    if ([[self screenOfCurrentToggleDisplay] containsDock]) {
        [NSApp setPresentationOptions:NSApplicationPresentationHideDock | NSApplicationPresentationDisableProcessSwitching | NSApplicationPresentationDisableAppleMenu | NSApplicationPresentationDisableHideApplication];
        dockIsHidden = YES;
    }
}

- (CGImageRef)snapshotOfDisplayWithID:(CGDirectDisplayID)displayID
{
    return CGDisplayCreateImageForRect(displayID, CGRectMake(0, 0 + [self thicknessOfSystemStatusBarForCurrentToggleDisplay],
                                                             NSWidth(self.currentToggleDisplayFrame),
                                                             NSHeight(self.currentToggleDisplayFrame) - [self thicknessOfSystemStatusBarForCurrentToggleDisplay]));
}

- (CGDirectDisplayID)displayIDForCurrentToggleDisplay:(CNToggleDisplay)aToggleDisplay
{
    uint32_t MAX_TOGGLE_DISPLAYS = 16;   // number of supported displays
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

- (void)dragCoverageUsingAnchorPoint:(NSPoint)location
{
    if (!self.isResizingAllowed)
        return;

    NSRect firstCoverFrame = [applicationFirstCoverView frame];
    NSRect secondCoverFrame = [applicationSecondCoverView frame];
    if (!NSPointInRect(location, firstCoverFrame) && !NSPointInRect(location, secondCoverFrame))
        return;

    location = NSMakePoint(ceil(location.x), ceil(location.y));
    if (applicationCoverIsDragging == NO) {
        applicationCoverIsDragging = YES;
        initialDraggingPoint = location;
        initialApplicationViewFrame = applicationView.frame;
        initialFirstCoverOrigin = [applicationFirstCoverView frame].origin;
        initialSecondCoverOrigin = [applicationSecondCoverView frame].origin;
    }

    NSRect appRect = NSZeroRect;
    CGFloat offset;
    
    switch (self.toggleEdge) {
        case CNToggleEdgeTop: {
            offset = location.y - initialDraggingPoint.y;
            firstCoverFrame = NSMakeRect(NSMinX(firstCoverFrame), initialFirstCoverOrigin.y + offset, NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
            appRect = NSMakeRect(NSMinX(applicationView.frame), NSMaxY(firstCoverFrame), NSWidth(applicationView.frame), NSHeight(initialApplicationViewFrame) - offset);
            if (NSMinY(firstCoverFrame) <= 0 && NSHeight(appRect) >= self.applicationViewMinSize.height) {
                applicationView.frame = appRect;
                applicationFirstCoverView.layer.frame = firstCoverFrame;
            }
            break;
        }
        case CNToggleEdgeBottom: {
            offset = location.y - initialDraggingPoint.y;
            firstCoverFrame = NSMakeRect(NSMinX(firstCoverFrame), initialFirstCoverOrigin.y + offset, NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
            appRect = NSMakeRect(NSMinX(applicationView.frame), NSMinY(applicationView.frame), NSWidth(applicationView.frame), NSHeight(initialApplicationViewFrame) + offset);
            if (NSMaxY(firstCoverFrame) >= 0 && NSHeight(appRect) >= self.applicationViewMinSize.height) {
                applicationView.frame = appRect;
                applicationFirstCoverView.layer.frame = firstCoverFrame;
            }
            break;
        }
        case CNToggleEdgeLeft: {
            offset = location.x - initialDraggingPoint.x;
            firstCoverFrame = NSMakeRect(initialFirstCoverOrigin.x + offset, NSMinY(firstCoverFrame), NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
            appRect = NSMakeRect(NSMinX(applicationView.frame), NSMinY(applicationView.frame), NSWidth(initialApplicationViewFrame) + offset, NSHeight(applicationView.frame));
            if (NSMinX(firstCoverFrame) >= 0 && NSWidth(appRect) >= self.applicationViewMinSize.width) {
                applicationView.frame = appRect;
                applicationFirstCoverView.layer.frame = firstCoverFrame;
            }
            break;
        }
        case CNToggleEdgeRight: {
            offset = location.x - initialDraggingPoint.x;
            firstCoverFrame = NSMakeRect(initialFirstCoverOrigin.x + offset, NSMinY(firstCoverFrame), NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
            appRect = NSMakeRect(NSMaxX(firstCoverFrame) + 1, NSMinY(applicationView.frame), NSWidth(initialApplicationViewFrame) - offset, NSHeight(applicationView.frame));
            if (NSMinX(firstCoverFrame) <= 0 && NSWidth(appRect) >= self.applicationViewMinSize.width) {
                applicationView.frame = appRect;
                applicationFirstCoverView.layer.frame = firstCoverFrame;
            }
            break;
        }
        case CNToggleEdgeSplitHorizontal: {
            offset = location.x - initialDraggingPoint.x;
            if (NSPointInRect(location, firstCoverFrame)) {
                firstCoverFrame = NSMakeRect(initialFirstCoverOrigin.x + offset, NSMinY(firstCoverFrame), NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
                secondCoverFrame = NSMakeRect(initialSecondCoverOrigin.x - offset, NSMinY(secondCoverFrame), NSWidth(secondCoverFrame), NSHeight(secondCoverFrame));
            } else {
                secondCoverFrame = NSMakeRect(initialSecondCoverOrigin.x + offset, NSMinY(secondCoverFrame), NSWidth(secondCoverFrame), NSHeight(secondCoverFrame));
                firstCoverFrame = NSMakeRect(initialFirstCoverOrigin.x - offset, NSMinY(firstCoverFrame), NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
            }
            appRect = NSMakeRect(NSMaxX(firstCoverFrame) - 1, NSMinY(applicationView.frame), NSMinX(secondCoverFrame) - NSMaxX(firstCoverFrame) + 1, NSHeight(applicationView.frame));
            if (NSMaxX(firstCoverFrame) >= 0 && NSMinX(firstCoverFrame) <= 0 && NSWidth(appRect) >= self.applicationViewMinSize.width) {
                applicationView.frame = appRect;
                applicationFirstCoverView.layer.frame = firstCoverFrame;
                applicationSecondCoverView.layer.frame = secondCoverFrame;
            }
            break;
        }
        case CNToggleEdgeSplitVertical: {
            offset = location.y - initialDraggingPoint.y;
            if (NSPointInRect(location, firstCoverFrame)) {
                firstCoverFrame = NSMakeRect(NSMinX(firstCoverFrame), initialFirstCoverOrigin.y + offset, NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
                secondCoverFrame = NSMakeRect(NSMinX(secondCoverFrame), initialSecondCoverOrigin.y - offset, NSWidth(secondCoverFrame), NSHeight(secondCoverFrame));
            } else {
                firstCoverFrame = NSMakeRect(NSMinX(firstCoverFrame), initialFirstCoverOrigin.y - offset, NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
                secondCoverFrame = NSMakeRect(NSMinX(secondCoverFrame), initialSecondCoverOrigin.y + offset, NSWidth(secondCoverFrame), NSHeight(secondCoverFrame));
            }
            appRect = NSMakeRect(NSMinX(applicationView.frame), NSMaxY(secondCoverFrame) - 1, NSWidth(applicationView.frame), NSMinY(firstCoverFrame) - NSMaxY(secondCoverFrame) + 1);
            if (NSMinY(secondCoverFrame) <= 0 && NSHeight(appRect) >= self.applicationViewMinSize.height) {
                applicationView.frame = appRect;
                applicationFirstCoverView.layer.frame = firstCoverFrame;
                applicationSecondCoverView.layer.frame = secondCoverFrame;
            }
            break;
        }
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSResponder

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (applicationCoverIsDragging == NO) {
        /// inform the delegate
        [self backstageController:self willDragOnScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];
    }
    [self dragCoverageUsingAnchorPoint:[theEvent locationInWindow]];
}

- (void)mouseDown:(NSEvent *)theEvent
{
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (!NSPointInRect([theEvent locationInWindow], [applicationView frame])) {
        if (applicationCoverIsDragging == NO) {
            [self collapse];
        } else {
            applicationCoverIsDragging = NO;
            applicationFirstCoverView.frame = applicationFirstCoverView.layer.frame;
            applicationSecondCoverView.frame = applicationSecondCoverView.layer.frame;

            /// inform the delegate
            [self backstageController:self didDragOnScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];
        }
    }
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    if (!NSPointInRect([theEvent locationInWindow], [applicationView frame])) {
        [self collapse];
    }
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
    if (!NSPointInRect([theEvent locationInWindow], [applicationView frame])) {
        [self collapse];
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Notifications

- (void)willResignActive:(NSNotification *)notification
{
    if ([self currentViewState] == CNToggleStateExpanded) {
        [self collapse];
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstage Delegate Callbacks

- (void)backstageController:(CNBackstageController *)backstageController willExpandOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    [notifCenter postNotificationName:CNBackstageControllerWillExpandOnScreenNotification
                                    object:backstageController
                                  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                            toggleScreen, CNToggleScreenUserInfoKey,
                                            [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                                            nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController willExpandOnScreen:toggleScreen onToggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController didExpandOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    [notifCenter postNotificationName:CNBackstageControllerDidExpandOnScreenNotification
                                    object:backstageController
                                  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                            toggleScreen, CNToggleScreenUserInfoKey,
                                            [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                                            nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController didExpandOnScreen:toggleScreen onToggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController willCollapseOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    [notifCenter postNotificationName:CNBackstageControllerWillCollapseOnScreenNotification
                                    object:backstageController
                                  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                            toggleScreen, CNToggleScreenUserInfoKey,
                                            [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                                            nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController willCollapseOnScreen:toggleScreen onToggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController didCollapseOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    [notifCenter postNotificationName:CNBackstageControllerDidCollapseOnScreenNotification
                                    object:backstageController
                                  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                            toggleScreen, CNToggleScreenUserInfoKey,
                                            [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                                            nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController didCollapseOnScreen:toggleScreen onToggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController willDragOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    [notifCenter postNotificationName:CNBackstageControllerWillDragOnScreenNotification
                               object:backstageController
                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                       toggleScreen, CNToggleScreenUserInfoKey,
                                       [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                                       nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController willDragOnScreen:toggleScreen onToggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController didDragOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    [notifCenter postNotificationName:CNBackstageControllerDidDragOnScreenNotification
                               object:backstageController
                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                       toggleScreen, CNToggleScreenUserInfoKey,
                                       [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                                       nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController didDragOnScreen:toggleScreen onToggleEdge:toggleEdge];
    }
}


@end
