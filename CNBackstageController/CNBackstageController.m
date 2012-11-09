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

/// NSUserDefaults keys to save the enum values
NSString *CNToggleEdgePreferencesKey = @"CNToggleEdge";
NSString *CNToggleSizePreferencesKey = @"CNToggleSize";
NSString *CNToggleDisplayPreferencesKey = @"CNToggleDisplay";
NSString *CNToggleVisualEffectPreferencesKey = @"CNToggleVisualEffect";
NSString *CNToggleAnimationEffectPreferencesKey = @"CNToggleAnimationEffect";
NSString *CNToggleAlphaValuePreferencesKey = @"CNToggleAlphaValue";

/// Notifications
NSString *CNBackstageControllerWillOpenScreenNotification = @"CNBackstageControllerWillOpenScreen";
NSString *CNBackstageControllerDidOpenScreenNotification = @"CNBackstageControllerDidOpenScreen";
NSString *CNBackstageControllerWillCloseScreenNotification = @"CNBackstageControllerWillCloseScreen";
NSString *CNBackstageControllerDidCloseScreenNotification = @"CNBackstageControllerDidCloseScreen";

/// Keys that are used for the userInfo dictionary in the notifications from above
NSString *CNToggleScreenUserInfoKey = @"toggleScreen";
NSString *CNToggleEdgeUserInfoKey = @"toggleEdge";



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstageController Extension

@interface CNBackstageController() {
    NSApplicationPresentationOptions presentationOptionsBackup;
    NSNotificationCenter *notifCenter;
    NSView *applicationView;
    NSView *applicationFirstCoverView;
    NSView *applicationFirstCoverOverlayView;
    NSView *applicationSecondCoverView;
    NSView *applicationSecondCoverOverlayView;
    CNBackstageShadowView *shadowView;
    NSPoint initialDraggingPoint;
    NSPoint initialFirstCoverSlidingPoint;
    NSPoint initialSecondCoverSlidingPoint;
    NSRect initialApplicationViewFrame;
    NSRect initialShadowViewFrame;
    CNToggleState toggleState;
    BOOL dockIsHidden;
    BOOL toggleAnimationIsRunning;
    BOOL applicationCoverIsDragging;
    CIFilter *gaussianBlurFilter;
}
@property (readonly) NSRect currentToggleDisplayFrame;

- (void)changeViewStateToOpenUsingCompletionHandler:(void(^)(void))completionHandler;
- (void)changeViewStateToCloseUsingCompletionHandler:(void(^)(void))completionHandler;
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
- (void)slideApplicationCoverUsingCursorLocation:(NSPoint)location;
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
        _toggleEdge                             = CNToggleEdgeTop;
        _toggleSize                             = CNToggleSizeHalfScreen;
        _toggleDisplay                          = CNToggleDisplayMain;
        _toggleVisualEffect                     = CNToggleVisualEffectOverlayBlack;
        _toggleAnimationEffect                  = CNToggleAnimationEffectStatic;
        _userInteractionEnabled                 = YES;
        _applicationViewController              = nil;
        _backstageViewBackgroundColor           = [NSColor darkGrayColor];
        _overlayAlpha                           = 0.75;

        /// private properties
        notifCenter                             = [NSNotificationCenter defaultCenter];
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
        initialFirstCoverSlidingPoint              = NSZeroPoint;
        initialSecondCoverSlidingPoint             = NSZeroPoint;
        initialApplicationViewFrame              = NSZeroRect;
        initialShadowViewFrame                   = NSZeroRect;
        toggleState                             = CNToggleStateClosed;
        _delegate                               = nil;
    }
    return self;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - API

- (void)toggleViewState
{
    switch (toggleState) {
        case CNToggleStateClosed: [self changeViewStateToOpen]; break;
        case CNToggleStateOpened: [self changeViewStateToClose]; break;
    }
}

- (void)changeViewStateToOpen
{
    if (toggleAnimationIsRunning == NO) {
        toggleAnimationIsRunning = YES;

        [NSApp activateIgnoringOtherApps:YES];

        /// inform the delegate
        [self backstageController:self willOpenScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];

        [self changeViewStateToOpenUsingCompletionHandler:^{
            /// inform the delegate
            [self backstageController:self didOpenScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];
            toggleAnimationIsRunning = NO;
        }];
    }
}

- (void)changeViewStateToClose
{
    if (toggleAnimationIsRunning == NO) {
        toggleAnimationIsRunning = YES;

        /// inform the delegate
        [self backstageController:self willCloseScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];

        [self changeViewStateToCloseUsingCompletionHandler:^{
            /// inform the delegate
            [self backstageController:self didCloseScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];
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

- (void)setToggleSize:(CNToggleSize)aToggleSize
{
    if(aToggleSize < 0) {
        _toggleSize *= -1;
    }
    if(aToggleSize > NSHeight([self currentToggleDisplayFrame])) {
        _toggleSize = CNToggleSizeHalfScreen;

    } else {
        _toggleSize = aToggleSize;
    }
}

- (CGRect)currentToggleDisplayFrame
{
    return [[self screenOfCurrentToggleDisplay] frame];
}




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Helper

- (void)changeViewStateToOpenUsingCompletionHandler:(void(^)(void))completionHandler
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
            applicationView.alphaValue = 0.0;
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
                [[applicationView animator] setAlphaValue:1.0];
                break;
            }

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
        toggleState = CNToggleStateOpened;
        toggleAnimationIsRunning = NO;

        completionHandler();
    }];
}

- (void)changeViewStateToCloseUsingCompletionHandler:(void(^)(void))completionHandler
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

            case CNToggleAnimationEffectFade: {
                [[applicationView animator] setAlphaValue:0.0];
                break;
            }

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
        toggleState = CNToggleStateClosed;

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
        case CNToggleEdgeSplitHorizontal:  {
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
    [controllerWindow setReleasedWhenClosed:YES];
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
    applicationView.frame = [self frameOfApplicationView];
    [controllerWindowContentView addSubview:applicationView];

    // application shadow view
    shadowView = [[CNBackstageShadowView alloc] initWithFrame:[applicationView bounds]];
    shadowView.toggleEdge = self.toggleEdge;
    [applicationView addSubview:shadowView];

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

    if (self.userInteractionEnabled) {
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
            CGImageRef snapshotSecondSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(NSWidth(contentViewBounds)/2 + 1, NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds)));
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
            CGImageRef snapshotSecondSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(NSMinX(contentViewBounds), floor(NSHeight(contentViewBounds)/2)+1, NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2)));
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

- (void)slideApplicationCoverUsingCursorLocation:(NSPoint)location
{
    if (!self.userInteractionEnabled)
        return;

    NSRect firstSlidingCoverFrame = [applicationFirstCoverView frame];
    NSRect secondSlidingCoverFrame = [applicationSecondCoverView frame];
    if (!NSPointInRect(location, firstSlidingCoverFrame) && !NSPointInRect(location, secondSlidingCoverFrame))
        return;

    location = NSMakePoint(ceil(location.x), ceil(location.y));
    if (applicationCoverIsDragging == NO) {
        applicationCoverIsDragging = YES;
        initialDraggingPoint = location;
        initialApplicationViewFrame = applicationView.frame;
        initialShadowViewFrame = shadowView.frame;
        initialFirstCoverSlidingPoint = [applicationFirstCoverView frame].origin;
        initialSecondCoverSlidingPoint = [applicationSecondCoverView frame].origin;
    }

    NSRect appRect = NSZeroRect;
    NSRect shadowRect = NSZeroRect;
    CGFloat offset;
    
    switch (self.toggleEdge) {
        case CNToggleEdgeTop: {
            break;
        }
        case CNToggleEdgeBottom: {
            break;
        }
        case CNToggleEdgeLeft: {
            offset = location.x - initialDraggingPoint.x;
            firstSlidingCoverFrame = NSMakeRect(initialFirstCoverSlidingPoint.x + offset, NSMinY(firstSlidingCoverFrame), NSWidth(firstSlidingCoverFrame), NSHeight(firstSlidingCoverFrame));
            appRect = NSMakeRect(NSMinX(applicationView.frame), NSMinY(applicationView.frame), NSWidth(initialApplicationViewFrame) + offset, NSHeight(applicationView.frame));
            shadowRect = NSMakeRect(NSMinX(shadowView.frame), NSMinY(shadowView.frame), NSWidth(initialShadowViewFrame) + offset, NSHeight(shadowView.frame));
            if (NSMinX(firstSlidingCoverFrame) >= 0) {
                applicationView.frame = appRect;
                shadowView.frame = shadowRect;
                applicationFirstCoverView.layer.frame = firstSlidingCoverFrame;
            }
            break;
        }
        case CNToggleEdgeRight: {
            offset = location.x - initialDraggingPoint.x;
            firstSlidingCoverFrame = NSMakeRect(initialFirstCoverSlidingPoint.x + offset, NSMinY(firstSlidingCoverFrame), NSWidth(firstSlidingCoverFrame), NSHeight(firstSlidingCoverFrame));
            appRect = NSMakeRect(NSMaxX(firstSlidingCoverFrame) + 1, NSMinY(applicationView.frame), NSWidth(initialApplicationViewFrame) - offset, NSHeight(applicationView.frame));
            shadowRect = NSMakeRect(NSMinX(shadowView.frame), NSMinY(shadowView.frame), NSWidth(initialShadowViewFrame) - offset, NSHeight(shadowView.frame));
            if (NSMaxX(firstSlidingCoverFrame) <= NSWidth(firstSlidingCoverFrame)) {
                applicationView.frame = appRect;
                shadowView.frame = shadowRect;
                applicationFirstCoverView.layer.frame = firstSlidingCoverFrame;
            }
            break;
        }
        case CNToggleEdgeSplitHorizontal: {
            break;
        }
        case CNToggleEdgeSplitVertical: {
            break;
        }
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSResponder

- (void)mouseDragged:(NSEvent *)theEvent
{
    [self slideApplicationCoverUsingCursorLocation:[theEvent locationInWindow]];
}

- (void)mouseDown:(NSEvent *)theEvent
{
}
//
- (void)mouseUp:(NSEvent *)theEvent
{
    if (!NSPointInRect([theEvent locationInWindow], [applicationView frame])) {
        if (applicationCoverIsDragging == NO) {
            [self changeViewStateToClose];
        } else {
            applicationCoverIsDragging = NO;
            applicationFirstCoverView.frame = applicationFirstCoverView.layer.frame;
        }
    }
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    if (!NSPointInRect([theEvent locationInWindow], [applicationView frame])) {
        [self changeViewStateToClose];
    }
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
    if (!NSPointInRect([theEvent locationInWindow], [applicationView frame])) {
        [self changeViewStateToClose];
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Notifications

- (void)willResignActive:(NSNotification *)notification
{
    if ([self currentViewState] == CNToggleStateOpened) {
        [self changeViewStateToClose];
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstage Delegate Callbacks

- (void)backstageController:(CNBackstageController *)backstageController willOpenScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    [notifCenter postNotificationName:CNBackstageControllerWillOpenScreenNotification
                                    object:backstageController
                                  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                            toggleScreen, CNToggleScreenUserInfoKey,
                                            [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                                            nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController willOpenScreen:toggleScreen onToggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController didOpenScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    [notifCenter postNotificationName:CNBackstageControllerDidOpenScreenNotification
                                    object:backstageController
                                  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                            toggleScreen, CNToggleScreenUserInfoKey,
                                            [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                                            nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController didOpenScreen:toggleScreen onToggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController willCloseScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    [notifCenter postNotificationName:CNBackstageControllerWillCloseScreenNotification
                                    object:backstageController
                                  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                            toggleScreen, CNToggleScreenUserInfoKey,
                                            [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                                            nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController willCloseScreen:toggleScreen onToggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController didCloseScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    [notifCenter postNotificationName:CNBackstageControllerDidCloseScreenNotification
                                    object:backstageController
                                  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                            toggleScreen, CNToggleScreenUserInfoKey,
                                            [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                                            nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController didCloseScreen:toggleScreen onToggleEdge:toggleEdge];
    }
}

@end
