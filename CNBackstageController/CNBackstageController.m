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
#pragma mark CNBackstageController Extension

@interface CNBackstageController() {
    NSApplicationPresentationOptions presentationOptionsBackup;
}
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
@property (strong) CIFilter *gaussianBlurFilter;
@property (strong) NSNotificationCenter *notifCenter;

#pragma mark - Helper
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

        _notifCenter                            = [NSNotificationCenter defaultCenter];
    }
    return self;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public API

- (void)toggleViewState
{
    switch (self.toggleState) {
        case CNToggleStateClosed: [self changeViewStateToOpen]; break;
        case CNToggleStateOpened: [self changeViewStateToClose]; break;
    }
}

- (void)changeViewStateToOpen
{
    if (self.toggleAnimationIsRunning == NO) {
        self.toggleAnimationIsRunning = YES;

        [NSApp activateIgnoringOtherApps:YES];

        /// inform the delegate
        [self backstageController:self willOpenScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];

        [self changeViewStateToOpenUsingCompletionHandler:^{
            /// inform the delegate
            [self backstageController:self didOpenScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];
            self.toggleAnimationIsRunning = NO;
        }];
    }
}

- (void)changeViewStateToClose
{
    if (self.toggleAnimationIsRunning == NO) {
        self.toggleAnimationIsRunning = YES;

        /// inform the delegate
        [self backstageController:self willCloseScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];

        [self changeViewStateToCloseUsingCompletionHandler:^{
            /// inform the delegate
            [self backstageController:self didCloseScreen:[self screenOfCurrentToggleDisplay] onToggleEdge:self.toggleEdge];
            self.toggleAnimationIsRunning = NO;
        }];
    }
}

- (CNToggleState)currentViewState
{
    return self.toggleState;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors

- (void)setApplicationViewController:(NSViewController<CNBackstageDelegate> *)applicationViewController
{
    _applicationViewController = applicationViewController;
    self.applicationView = [_applicationViewController view];
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

- (void)changeViewStateToOpenUsingCompletionHandler:(void(^)(void))completionHandler
{
    [self initializeApplicationWindow];
    [self buildLayerHierarchy];
    [self createSnapshotOfCurrentToggleDisplay];
    [self setupPresentationOptions];


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
                screenSnapshotFirstFrame.origin.x -= ceil(NSWidth(applicationFrame)/2)-1;
                screenSnapshotSecondFrame.origin.x += ceil(NSWidth(applicationFrame)/2)-1;
                break;

            case CNToggleEdgeSplitVertical:
                screenSnapshotFirstFrame.origin.y += ceil(NSHeight(applicationFrame)/2)-1;
                screenSnapshotSecondFrame.origin.y -= ceil(NSHeight(applicationFrame)/2)-1;
                break;
        }

        [self activateVisualEffects];
        [[self.viewOfFirstPartialDisplaySnapshot animator] setFrame:screenSnapshotFirstFrame];
        [[self.viewOfSecondPartialDisplaySnapshot animator] setFrame:screenSnapshotSecondFrame];


    } completionHandler:^{
        self.toggleState = CNToggleStateOpened;
        self.toggleAnimationIsRunning = NO;

        completionHandler();
    }];
}

- (void)changeViewStateToCloseUsingCompletionHandler:(void(^)(void))completionHandler
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
                screenSnapshotFirstFrame.origin.x += ceil(NSWidth(applicationFrame)/2)-1;
                screenSnapshotSecondFrame.origin.x -= ceil(NSWidth(applicationFrame)/2)-1;
                break;

            case CNToggleEdgeSplitVertical:
                screenSnapshotFirstFrame.origin.y -= ceil(NSHeight(applicationFrame)/2)-1;
                screenSnapshotSecondFrame.origin.y += ceil(NSHeight(applicationFrame)/2)-1;
                break;
        }

        [self deactivateVisualEffects];
        [[self.viewOfFirstPartialDisplaySnapshot animator] setFrame:screenSnapshotFirstFrame];
        [[self.viewOfSecondPartialDisplaySnapshot animator] setFrame:screenSnapshotSecondFrame];


    } completionHandler:^{
        [self.overlayOfFirstPartialDisplaySnapshot.layer setFilters:nil];
        [self.overlayOfSecondPartialDisplaySnapshot.layer setFilters:nil];
        [self restorePresentationOptions];
        [self resignApplicationWindow];

        self.toggleAnimationIsRunning = NO;
        self.toggleState = CNToggleStateClosed;

        completionHandler();
    }];
}

- (void)activateVisualEffects
{
    if (self.toggleVisualEffect == 0)
        return;

    if (self.toggleVisualEffect & CNToggleVisualEffectOverlayBlack) {
        self.overlayOfFirstPartialDisplaySnapshot.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
        [[self.overlayOfFirstPartialDisplaySnapshot animator] setAlphaValue:self.overlayAlpha];
        self.overlayOfSecondPartialDisplaySnapshot.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
        [[self.overlayOfSecondPartialDisplaySnapshot animator] setAlphaValue:self.overlayAlpha];
    }

    if (self.toggleVisualEffect & CNToggleVisualEffectGaussianBlur) {
        self.gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [self.gaussianBlurFilter setDefaults];
        [self.gaussianBlurFilter setValue:[NSNumber numberWithFloat:2] forKey:@"inputRadius"];
        [self.overlayOfFirstPartialDisplaySnapshot.layer setMasksToBounds:YES];
        [self.overlayOfSecondPartialDisplaySnapshot.layer setMasksToBounds:YES];
        [self.overlayOfFirstPartialDisplaySnapshot.layer setBackgroundFilters:@[self.gaussianBlurFilter]];
        [self.overlayOfSecondPartialDisplaySnapshot.layer setBackgroundFilters:@[self.gaussianBlurFilter]];
    }
}

- (void)deactivateVisualEffects
{
    if (self.toggleVisualEffect == 0)
        return;

    if (self.toggleVisualEffect & CNToggleVisualEffectOverlayBlack) {
        [[self.overlayOfFirstPartialDisplaySnapshot animator] setAlphaValue:0.0];
        [[self.overlayOfSecondPartialDisplaySnapshot animator] setAlphaValue:0.0];
    }

    if (self.toggleVisualEffect & CNToggleVisualEffectGaussianBlur) {
        [self.gaussianBlurFilter setValue:[NSNumber numberWithFloat:0] forKey:@"inputRadius"];
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
            self.viewOfFirstPartialDisplaySnapshot.frame = contentViewBounds;
            self.viewOfFirstPartialDisplaySnapshot.layer.contents = (__bridge id)(snapshotRef);

            self.overlayOfFirstPartialDisplaySnapshot.frame = contentViewBounds;
            break;
        }

        case CNToggleEdgeSplitHorizontal: {
            self.viewOfFirstPartialDisplaySnapshot.frame = NSMakeRect(NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds));
            CGImageRef snapshotFirstSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds)));
            self.overlayOfFirstPartialDisplaySnapshot.frame = self.viewOfFirstPartialDisplaySnapshot.bounds;

            self.viewOfSecondPartialDisplaySnapshot.frame = NSMakeRect(NSWidth(contentViewBounds)/2 + 1, NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds));
            CGImageRef snapshotSecondSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(NSWidth(contentViewBounds)/2 + 1, NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds)));
            self.overlayOfSecondPartialDisplaySnapshot.frame = self.viewOfSecondPartialDisplaySnapshot.bounds;

            self.viewOfFirstPartialDisplaySnapshot.layer.contents = (__bridge id)(snapshotFirstSplit);
            self.viewOfSecondPartialDisplaySnapshot.layer.contents = (__bridge id)(snapshotSecondSplit);
            CGImageRelease(snapshotFirstSplit);
            CGImageRelease(snapshotSecondSplit);
            break;
        }

        case CNToggleEdgeSplitVertical:
            self.viewOfFirstPartialDisplaySnapshot.frame = NSMakeRect(NSMinX(contentViewBounds), NSMaxY(contentViewBounds) - floor(NSHeight(contentViewBounds)/2), NSWidth(contentViewBounds),floor( NSHeight(contentViewBounds)/2));
            CGImageRef snapshotFirstSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2)));
            self.overlayOfFirstPartialDisplaySnapshot.frame = self.viewOfFirstPartialDisplaySnapshot.bounds;

            self.viewOfSecondPartialDisplaySnapshot.frame = NSMakeRect(NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2));
            CGImageRef snapshotSecondSplit = CGImageCreateWithImageInRect(snapshotRef, CGRectMake(NSMinX(contentViewBounds), floor(NSHeight(contentViewBounds)/2)+1, NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2)));
            self.overlayOfSecondPartialDisplaySnapshot.frame = self.viewOfSecondPartialDisplaySnapshot.bounds;

            self.viewOfFirstPartialDisplaySnapshot.layer.contents = (__bridge id)(snapshotFirstSplit);
            self.viewOfSecondPartialDisplaySnapshot.layer.contents = (__bridge id)(snapshotSecondSplit);
            CGImageRelease(snapshotFirstSplit);
            CGImageRelease(snapshotSecondSplit);
            break;
    }
    CGImageRelease(snapshotRef);
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

- (void)restorePresentationOptions
{
    if (self.dockIsHidden) {
        [NSApp setPresentationOptions:presentationOptionsBackup];
        self.dockIsHidden = NO;
    }
}

- (void)setupPresentationOptions
{
    [self showWindow:nil];
    presentationOptionsBackup = [NSApp currentSystemPresentationOptions];
    if ([[self screenOfCurrentToggleDisplay] containsDock]) {
        [NSApp setPresentationOptions:NSApplicationPresentationHideDock | NSApplicationPresentationDisableProcessSwitching | NSApplicationPresentationDisableAppleMenu | NSApplicationPresentationDisableHideApplication];
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
    if ([self currentViewState] == CNToggleStateOpened) {
        [self changeViewStateToClose];
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstage Delegate Callbacks

- (void)backstageController:(CNBackstageController *)backstageController willOpenScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge
{
    [self.notifCenter postNotificationName:CNBackstageControllerWillOpenScreenNotification
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
    [self.notifCenter postNotificationName:CNBackstageControllerDidOpenScreenNotification
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
    [self.notifCenter postNotificationName:CNBackstageControllerWillCloseScreenNotification
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
    [self.notifCenter postNotificationName:CNBackstageControllerDidCloseScreenNotification
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





/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstageShadowView

static NSColor *startColor, *middleColor, *endColor, *darkLineColor, *lightLineColor;

@interface CNBackstageShadowView ()
@end
@implementation CNBackstageShadowView

+ (void)initialize
{
    startColor = [[NSColor blackColor] colorWithAlphaComponent:0.55];
    middleColor = [[NSColor blackColor] colorWithAlphaComponent:0.32];
    endColor = [[NSColor blackColor] colorWithAlphaComponent:0.001];
    darkLineColor = [NSColor colorWithCalibratedRed:0.046 green:0.047 blue:0.047 alpha:1.000];
    lightLineColor = [NSColor colorWithDeviceRed:0.679 green:0.698 blue:0.698 alpha:1.000];
}

- (void)setToggleEdge:(CNToggleEdge)toggleEdge
{
    _toggleEdge = toggleEdge;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    NSColor *shadowColor = [NSColor colorWithCalibratedRed:0.f green:0.f blue:0.f alpha:0.75];
    CGFloat shadowBlurRadius = 11.0f;

    switch (self.toggleEdge) {
        case CNToggleEdgeTop: {
            NSRect topRect = NSMakeRect(NSMinX(dirtyRect)-5, NSHeight(dirtyRect), NSWidth(dirtyRect)+10, 15);
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];

            CGContextSetShadowWithColor(context, CGSizeMake(0, -3), shadowBlurRadius, shadowColor.CGColor);
            [darkLineColor setFill];
            [topPath fill];

            NSRect leftRect = NSMakeRect(ceil(NSMinX(dirtyRect))-10, NSMinY(dirtyRect)-5, 11, NSHeight(dirtyRect)+10);
            NSBezierPath *leftPath = [NSBezierPath bezierPathWithRect:leftRect];

            CGContextSetShadowWithColor(context, CGSizeMake(3, 0), shadowBlurRadius, shadowColor.CGColor);
            [darkLineColor setFill];
            [leftPath fill];

            NSRect bottomRect = NSMakeRect(NSMinX(dirtyRect), floor(NSMinY(dirtyRect)), NSWidth(dirtyRect), 1);
            NSBezierPath *bottomPath = [NSBezierPath bezierPathWithRect:bottomRect];
            [lightLineColor setFill];
            [bottomPath fill];
            break;
        }
        case CNToggleEdgeRight: {
            NSRect leftRect = NSMakeRect(ceil(NSMinX(dirtyRect))-10, NSMinY(dirtyRect)-5, 11, NSHeight(dirtyRect)+5);
            NSBezierPath *leftPath = [NSBezierPath bezierPathWithRect:leftRect];

            CGContextSetShadowWithColor(context, CGSizeMake(3, 0), shadowBlurRadius, shadowColor.CGColor);
            [darkLineColor setFill];
            [leftPath fill];

            NSRect topRect = NSMakeRect(NSMinX(dirtyRect), NSHeight(dirtyRect), NSWidth(dirtyRect)+5, 15);
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
            CGContextSetShadowWithColor(context, CGSizeMake(0, -3), shadowBlurRadius, shadowColor.CGColor);
            [darkLineColor setFill];
            [topPath fill];
            break;
        }
        case CNToggleEdgeBottom: {
            NSRect topRect = NSMakeRect(NSMinX(dirtyRect)-5, ceil(NSMaxY(dirtyRect))-1, NSWidth(dirtyRect)+10, 15);
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];

            CGContextSetShadowWithColor(context, CGSizeMake(0, -3), shadowBlurRadius, shadowColor.CGColor);
            [darkLineColor setFill];
            [topPath fill];
            break;
        }
        case CNToggleEdgeLeft: {
            NSRect rightRect = NSMakeRect(floor(NSWidth(dirtyRect))-1, NSMinY(dirtyRect)-5, 7, NSHeight(dirtyRect)+10);
            NSBezierPath *rightPath = [NSBezierPath bezierPathWithRect:rightRect];
            [lightLineColor setFill];
            [rightPath fill];

            NSRect leftRect = NSMakeRect(floor(NSMinX(dirtyRect))-10, NSMinY(dirtyRect)-5, 10, NSHeight(dirtyRect)+5);
            NSBezierPath *leftPath = [NSBezierPath bezierPathWithRect:leftRect];
            CGContextSetShadowWithColor(context, CGSizeMake(3, 0), shadowBlurRadius, shadowColor.CGColor);
            [darkLineColor setFill];
            [leftPath fill];

            NSRect topRect = NSMakeRect(NSMinX(dirtyRect), NSHeight(dirtyRect), NSWidth(dirtyRect)+5, 15);
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
            CGContextSetShadowWithColor(context, CGSizeMake(0, -3), shadowBlurRadius, shadowColor.CGColor);
            [darkLineColor setFill];
            [topPath fill];
            break;
        }

        case CNToggleEdgeSplitHorizontal: {
            NSRect leftRect = NSMakeRect(floor(NSMinX(dirtyRect))-9, NSMinY(dirtyRect)-5, 11, NSHeight(dirtyRect)+5);
            NSBezierPath *linePath = [NSBezierPath bezierPathWithRect:leftRect];
            CGContextSetShadowWithColor(context, CGSizeMake(3, 0), shadowBlurRadius, shadowColor.CGColor);
            [darkLineColor setFill];
            [linePath fill];

            NSRect topRect = NSMakeRect(NSMinX(dirtyRect), NSHeight(dirtyRect), NSWidth(dirtyRect)+5, 15);
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
            CGContextSetShadowWithColor(context, CGSizeMake(0, -3), shadowBlurRadius, shadowColor.CGColor);
            [darkLineColor setFill];
            [topPath fill];

            NSRect rightRect = NSMakeRect(NSMaxX(dirtyRect)-1, NSMinY(dirtyRect), 1, NSHeight(dirtyRect));
            linePath = [NSBezierPath bezierPathWithRect:rightRect];
            [lightLineColor setFill];
            [linePath fill];
            break;
        }

        case CNToggleEdgeSplitVertical: {
            NSRect topRect = NSMakeRect(NSMinX(dirtyRect)-5, floor(NSHeight(dirtyRect))-1, NSWidth(dirtyRect)+10, 15);
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
            CGContextSetShadowWithColor(context, CGSizeMake(0, -3), shadowBlurRadius, shadowColor.CGColor);
            [darkLineColor setFill];
            [topPath fill];

            NSRect leftRect = NSMakeRect(floor(NSMinX(dirtyRect))-10, NSMinY(dirtyRect)-5, 10, NSHeight(dirtyRect)+5);
            NSBezierPath *leftPath = [NSBezierPath bezierPathWithRect:leftRect];
            CGContextSetShadowWithColor(context, CGSizeMake(3, 0), shadowBlurRadius, shadowColor.CGColor);
            [darkLineColor setFill];
            [leftPath fill];

            NSRect lineBottomRect = NSMakeRect(NSMinX(dirtyRect), ceil(NSMinY(dirtyRect))+1, NSWidth(dirtyRect), 1);
            NSBezierPath *lineBottomPath = [NSBezierPath bezierPathWithRect:lineBottomRect];
            [lightLineColor setFill];
            [lineBottomPath fill];
            break;
        }
    }
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    // pass-through all events
    __block NSView *targetView = nil;
    [[self subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSView *subView = (NSView *)obj;
        if (![subView isHidden] && [subView hitTest:aPoint]) {
            targetView = subView;
            *stop = YES;
        }
    }];
    return targetView;
}

@end
