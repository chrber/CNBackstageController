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


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstageController Extension

@interface CNBackstageController() {
    NSApplicationPresentationOptions _presentationOptionsBackup;
    NSNotificationCenter *_nc;
    NSUserDefaults *_defaults;
    NSView *_applicationView;
    NSView *_applicationFirstCoverView;
    NSView *_applicationFirstCoverOverlayView;
    NSView *_applicationSecondCoverView;
    NSView *_applicationSecondCoverOverlayView;
    CNBackstageShadowView *_shadowView;
    NSPoint _initialDraggingPoint;
    NSPoint _initialFirstCoverOrigin;
    NSPoint _initialSecondCoverOrigin;
    NSRect _initialApplicationViewFrame;
    CNToggleState _toggleState;
    BOOL _dockIsHidden;
    BOOL _toggleAnimationIsRunning;
    BOOL _applicationCoverIsDragging;
    CIFilter *_gaussianBlurFilter;
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
- (void)configurePresentationOptions;
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
        /// IVARs
        _nc                                 = [NSNotificationCenter defaultCenter];
        _defaults                           = [NSUserDefaults standardUserDefaults];
        _applicationCoverIsDragging         = NO;
        _toggleAnimationIsRunning           = NO;
        _dockIsHidden                       = NO;
        _applicationView                    = [[NSView alloc] init];
        _applicationFirstCoverView          = [[NSView alloc] init];
        _applicationFirstCoverOverlayView   = [[NSView alloc] init];
        _applicationSecondCoverView         = [[NSView alloc] init];
        _applicationSecondCoverOverlayView  = [[NSView alloc] init];
        _shadowView                         = [[CNBackstageShadowView alloc] init];
        _initialDraggingPoint               = NSZeroPoint;
        _initialFirstCoverOrigin            = NSZeroPoint;
        _initialSecondCoverOrigin           = NSZeroPoint;
        _initialApplicationViewFrame        = NSZeroRect;
        _toggleState                        = CNToggleStateCollapsed;

        /// properties of API
        _delegate                   = nil;
        _toggleEdge                 = CNToggleEdgeTop;
        _toggleSize                 = CNMakeToggleSize(CNToggleSizeQuarterScreen, CNToggleSizeQuarterScreen);
        _toggleDisplay              = CNToggleDisplayMain;
        _toggleVisualEffect         = CNToggleVisualEffectOverlayBlack;
        _toggleAnimationEffect      = CNToggleAnimationEffectStatic;
        _applicationViewController  = nil;
        _backgroundColor            = [NSColor darkGrayColor];
        _overlayAlpha               = 0.75f;
        _resizingAllowed            = YES;
        _toggleSizeMin              = NSMakeSize(200.0f, 120.0f);
        _useShadows                 = YES;
    }
    return self;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - API

- (void)toggleViewState
{
    NSAssert(self.applicationViewController != nil, @"\n\nThe applicationViewController property must NOT be nil!\nAfter you created your CNBackstageController instance you have to set applicationViewController property.\n\n");
    
    switch (_toggleState) {
        case CNToggleStateCollapsed: [self expand]; break;
        case CNToggleStateExpanded: [self collapse]; break;
    }
}

- (void)expand
{
    if (_toggleAnimationIsRunning == NO) {
        _toggleAnimationIsRunning = YES;

        [NSApp activateIgnoringOtherApps:YES];

        /// inform the delegate
        [self backstageController:self willExpandOnScreen:[self screenOfCurrentToggleDisplay] toggleEdge:self.toggleEdge];

        [self expandUsingCompletionHandler:^{
            /// inform the delegate
            [self backstageController:self didExpandOnScreen:[self screenOfCurrentToggleDisplay] toggleEdge:self.toggleEdge];
            _toggleAnimationIsRunning = NO;
        }];
    }
}

- (void)collapse
{
    if (_toggleAnimationIsRunning == NO) {
        _toggleAnimationIsRunning = YES;

        /// inform the delegate
        [self backstageController:self willCollapseOnScreen:[self screenOfCurrentToggleDisplay] toggleEdge:self.toggleEdge];

        [self collapseUsingCompletionHandler:^{
            /// inform the delegate
            [self backstageController:self didCollapseOnScreen:[self screenOfCurrentToggleDisplay] toggleEdge:self.toggleEdge];
            _toggleAnimationIsRunning = NO;
        }];
    }
}

- (CNToggleState)currentViewState
{
    return _toggleState;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors

- (void)setApplicationViewController:(NSViewController<CNBackstageDelegate> *)applicationViewController
{
    if (_applicationViewController != applicationViewController) {
        _applicationViewController = nil;
        _applicationViewController = applicationViewController;
        _applicationView = [_applicationViewController view];
        self.delegate = _applicationViewController;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willResignActive:)
                                                     name:NSApplicationWillResignActiveNotification
                                                   object:nil];
    }
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

                    else if (aToggleSize.width <= self.toggleSizeMin.width) {
                        /// fallback
                        width = self.toggleSizeMin.width;

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
                    if (aToggleSize.height <= windowHeight && aToggleSize.height >= self.toggleSizeMin.height) {
                        height = aToggleSize.height;
                    }

                    else if (aToggleSize.height <= self.toggleSizeMin.height) {
                        height = self.toggleSizeMin.height;

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
#pragma mark - Private Helper

- (void)expandUsingCompletionHandler:(void(^)(void))completionHandler
{
    [self initializeApplicationWindow];
    [self buildLayerHierarchy];
    [self createSnapshotOfCurrentToggleDisplay];
    [self configurePresentationOptions];


    __block NSRect applicationFrame = [_applicationView frame];
    __block NSRect screenSnapshotFirstFrame = [_applicationFirstCoverView frame];
    __block NSRect screenSnapshotSecondFrame = [_applicationSecondCoverView frame];

    switch (self.toggleAnimationEffect) {
        case CNToggleAnimationEffectFade:
            _applicationView.alphaValue = 0.0;
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

            case CNToggleAnimationEffectFade:
                [[_applicationView animator] setAlphaValue:1.0];
                break;

            case CNToggleAnimationEffectSlide: {
                switch (self.toggleEdge) {
                    case CNToggleEdgeTop:       applicationFrame.origin.y -= ceil(NSHeight(applicationFrame)); break;
                    case CNToggleEdgeBottom:    applicationFrame.origin.y += ceil(NSHeight(applicationFrame)); break;
                    case CNToggleEdgeLeft:      applicationFrame.origin.x += ceil(NSWidth(applicationFrame)); break;
                    case CNToggleEdgeRight:     applicationFrame.origin.x -= ceil(NSWidth(applicationFrame)); break;
                    default:
                        break;
                }
                [[_applicationView animator] setFrame:applicationFrame];
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
        [[_applicationFirstCoverView animator] setFrame:screenSnapshotFirstFrame];
        [[_applicationSecondCoverView animator] setFrame:screenSnapshotSecondFrame];


    } completionHandler:^{
        _toggleState = CNToggleStateExpanded;
        _toggleAnimationIsRunning = NO;

        completionHandler();
    }];
}

- (void)collapseUsingCompletionHandler:(void(^)(void))completionHandler
{
    __block NSRect applicationFrame = [_applicationView frame];
    __block NSRect screenSnapshotFirstFrame = [_applicationFirstCoverView frame];
    __block NSRect screenSnapshotSecondFrame = [_applicationSecondCoverView frame];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        switch (self.toggleAnimationEffect) {
            case CNToggleAnimationEffectStatic:
                break;

            case CNToggleAnimationEffectFade:
                [[_applicationView animator] setAlphaValue:0.0];
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
                [[_applicationView animator] setFrame:applicationFrame];
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
        [[_applicationFirstCoverView animator] setFrame:screenSnapshotFirstFrame];
        [[_applicationSecondCoverView animator] setFrame:screenSnapshotSecondFrame];


    } completionHandler:^{
        [_applicationFirstCoverOverlayView.layer setFilters:nil];
        [_applicationSecondCoverOverlayView.layer setFilters:nil];
        [self restorePresentationOptions];
        [self resignApplicationWindow];

        _toggleAnimationIsRunning = NO;
        _toggleState = CNToggleStateCollapsed;

        completionHandler();
    }];
}

- (void)activateVisualEffects
{
    if (self.toggleVisualEffect == 0)
        return;

    if (self.toggleVisualEffect & CNToggleVisualEffectOverlayBlack) {
        _applicationFirstCoverOverlayView.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
        [[_applicationFirstCoverOverlayView animator] setAlphaValue:self.overlayAlpha];
        _applicationSecondCoverOverlayView.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
        [[_applicationSecondCoverOverlayView animator] setAlphaValue:self.overlayAlpha];
    }

    if (self.toggleVisualEffect & CNToggleVisualEffectGaussianBlur) {
        _gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [_gaussianBlurFilter setDefaults];
        [_gaussianBlurFilter setValue:[NSNumber numberWithFloat:2] forKey:@"inputRadius"];
        [_applicationFirstCoverOverlayView.layer setMasksToBounds:YES];
        [_applicationSecondCoverOverlayView.layer setMasksToBounds:YES];
        [_applicationFirstCoverOverlayView.layer setBackgroundFilters:@[_gaussianBlurFilter]];
        [_applicationSecondCoverOverlayView.layer setBackgroundFilters:@[_gaussianBlurFilter]];
    }
}

- (void)deactivateVisualEffects
{
    if (self.toggleVisualEffect == 0)
        return;

    if (self.toggleVisualEffect & CNToggleVisualEffectOverlayBlack) {
        [[_applicationFirstCoverOverlayView animator] setAlphaValue:0.0];
        [[_applicationSecondCoverOverlayView animator] setAlphaValue:0.0];
    }

    if (self.toggleVisualEffect & CNToggleVisualEffectGaussianBlur) {
        [_gaussianBlurFilter setValue:[NSNumber numberWithFloat:0] forKey:@"inputRadius"];
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
    __weak NSView *controllerWindowContentView = [[self window] contentView];

    // Application
    _applicationView.frame = [self frameOfApplicationView];
    [controllerWindowContentView addSubview:_applicationView];

    // application shadow view
    _shadowView = [[CNBackstageShadowView alloc] initWithFrame:[_applicationView bounds]];
    _shadowView.toggleEdge = self.toggleEdge;
    _shadowView.useShadows = self.useShadows;
    [_shadowView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [_applicationView addSubview:_shadowView];

    // Screen Snapshot, First
    [controllerWindowContentView addSubview:_applicationFirstCoverView];
    [_applicationFirstCoverView addSubview:_applicationFirstCoverOverlayView];
    _applicationFirstCoverOverlayView.alphaValue = 0.0f;

    if (self.toggleEdge == CNToggleEdgeSplitHorizontal || self.toggleEdge == CNToggleEdgeSplitVertical) {
        [controllerWindowContentView addSubview:_applicationSecondCoverView];
        [_applicationSecondCoverView addSubview:_applicationSecondCoverOverlayView];
        _applicationSecondCoverOverlayView.alphaValue = 0.0f;
    }

    if (self.isResizingAllowed) {
        NSTrackingArea *firstTrackingArea = [[NSTrackingArea alloc] initWithRect:_applicationFirstCoverView.frame
                                                                         options:NSTrackingMouseEnteredAndExited | NSTrackingCursorUpdate | NSTrackingActiveInKeyWindow | NSTrackingEnabledDuringMouseDrag
                                                                           owner:self
                                                                        userInfo:nil];
        [_applicationFirstCoverView addTrackingArea:firstTrackingArea];

        NSTrackingArea *secondTrackingArea = [[NSTrackingArea alloc] initWithRect:_applicationSecondCoverView.frame
                                                                         options:NSTrackingMouseEnteredAndExited | NSTrackingCursorUpdate | NSTrackingActiveInKeyWindow | NSTrackingEnabledDuringMouseDrag
                                                                           owner:self
                                                                        userInfo:nil];
        [_applicationSecondCoverView addTrackingArea:secondTrackingArea];
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
    NSScreen *toggleScreen = [self screenOfCurrentToggleDisplay];

    switch (self.toggleEdge) {
        case CNToggleEdgeTop:
        case CNToggleEdgeBottom:
        case CNToggleEdgeLeft:
        case CNToggleEdgeRight: {
            _applicationFirstCoverView.frame = contentViewBounds;
            _applicationFirstCoverView.layer.contents = (__bridge id)(snapshotRef);
            _applicationFirstCoverOverlayView.frame = contentViewBounds;
            break;
        }

        case CNToggleEdgeSplitHorizontal: {
            _applicationFirstCoverView.frame = CGRectMake(NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds));
            CGImageRef snapshotFirstSplit = CGImageCreateWithImageInRect(snapshotRef, CNRectMake(toggleScreen, NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds)));
            _applicationFirstCoverOverlayView.frame = _applicationFirstCoverView.bounds;

            _applicationSecondCoverView.frame = CGRectMake(NSWidth(contentViewBounds)/2 + 1, NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds));
            CGImageRef snapshotSecondSplit = CGImageCreateWithImageInRect(snapshotRef, CNRectMake(toggleScreen, NSWidth(contentViewBounds)/2, NSMinY(contentViewBounds), NSWidth(contentViewBounds)/2, NSHeight(contentViewBounds)));
            _applicationSecondCoverOverlayView.frame = _applicationSecondCoverView.bounds;

            _applicationFirstCoverView.layer.contents = (__bridge id)(snapshotFirstSplit);
            _applicationSecondCoverView.layer.contents = (__bridge id)(snapshotSecondSplit);
            CGImageRelease(snapshotFirstSplit);
            CGImageRelease(snapshotSecondSplit);
            break;
        }

        case CNToggleEdgeSplitVertical:
            _applicationFirstCoverView.frame = CGRectMake(NSMinX(contentViewBounds), NSMaxY(contentViewBounds) - floor(NSHeight(contentViewBounds)/2), NSWidth(contentViewBounds),floor( NSHeight(contentViewBounds)/2));
            CGImageRef snapshotFirstSplit = CGImageCreateWithImageInRect(snapshotRef, CNRectMake(toggleScreen, NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2)));
            _applicationFirstCoverOverlayView.frame = _applicationFirstCoverView.bounds;

            _applicationSecondCoverView.frame = CGRectMake(NSMinX(contentViewBounds), NSMinY(contentViewBounds), NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2));
            CGImageRef snapshotSecondSplit = CGImageCreateWithImageInRect(snapshotRef, CNRectMake(toggleScreen, NSMinX(contentViewBounds), floor(NSHeight(contentViewBounds)/2), NSWidth(contentViewBounds), floor(NSHeight(contentViewBounds)/2)));
            _applicationSecondCoverOverlayView.frame = _applicationSecondCoverView.bounds;

            _applicationFirstCoverView.layer.contents = (__bridge id)(snapshotFirstSplit);
            _applicationSecondCoverView.layer.contents = (__bridge id)(snapshotSecondSplit);
            CGImageRelease(snapshotFirstSplit);
            CGImageRelease(snapshotSecondSplit);
            break;
    }
    CGImageRelease(snapshotRef);
}

- (void)resignApplicationWindow
{
    self.window.alphaValue = 0.0;
    
    [_shadowView removeFromSuperview];
    [_applicationFirstCoverOverlayView removeFromSuperview];
    [_applicationFirstCoverView removeFromSuperview];
    [_applicationSecondCoverOverlayView removeFromSuperview];
    [_applicationSecondCoverView removeFromSuperview];
    _applicationView.alphaValue = 1.0;

    _shadowView = [[CNBackstageShadowView alloc] init];
    _applicationFirstCoverView = [[NSView alloc] init];
    _applicationFirstCoverOverlayView = [[NSView alloc] init];
    _applicationSecondCoverView = [[NSView alloc] init];
    _applicationSecondCoverOverlayView = [[NSView alloc] init];
    [self.window close];
    self.window = nil;
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
    if (_dockIsHidden) {
        [NSApp setPresentationOptions:_presentationOptionsBackup];
        _dockIsHidden = NO;
    }
}

- (void)configurePresentationOptions
{
    [self showWindow:nil];
    _presentationOptionsBackup = [NSApp currentSystemPresentationOptions];
    if ([[self screenOfCurrentToggleDisplay] containsDock]) {
        [NSApp setPresentationOptions:NSApplicationPresentationHideDock | NSApplicationPresentationDisableProcessSwitching | NSApplicationPresentationDisableAppleMenu | NSApplicationPresentationDisableHideApplication];
        _dockIsHidden = YES;
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
    uint32_t MAX_TOGGLE_DISPLAYS = kMaxNumberOfSupportedDisplays;   // number of supported displays
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

    NSRect firstCoverFrame = [_applicationFirstCoverView frame];
    NSRect secondCoverFrame = [_applicationSecondCoverView frame];
    if (!NSPointInRect(location, firstCoverFrame) && !NSPointInRect(location, secondCoverFrame))
        return;

    location = NSMakePoint(ceil(location.x), ceil(location.y));
    if (_applicationCoverIsDragging == NO) {
        _applicationCoverIsDragging = YES;
        _initialDraggingPoint = location;
        _initialApplicationViewFrame = _applicationView.frame;
        _initialFirstCoverOrigin = [_applicationFirstCoverView frame].origin;
        _initialSecondCoverOrigin = [_applicationSecondCoverView frame].origin;
    }

    NSRect appRect = NSZeroRect;
    CGFloat offset;
    NSScreen *toggleScreen = [self screenOfCurrentToggleDisplay];
    
    switch (self.toggleEdge) {
        case CNToggleEdgeTop: {
            offset = location.y - _initialDraggingPoint.y;
            firstCoverFrame = CGRectMake(NSMinX(firstCoverFrame), _initialFirstCoverOrigin.y + offset, NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
            appRect = CGRectMake(NSMinX(_applicationView.frame), NSMaxY(firstCoverFrame), NSWidth(_applicationView.frame), NSHeight(_initialApplicationViewFrame) - offset);
            if (NSMinY(firstCoverFrame) <= 0 && NSHeight(appRect) >= self.toggleSizeMin.height) {
                _applicationView.frame = appRect;
                _applicationFirstCoverView.layer.frame = firstCoverFrame;
            }
            break;
        }
        case CNToggleEdgeBottom: {
            offset = location.y - _initialDraggingPoint.y;
            firstCoverFrame = CGRectMake(NSMinX(firstCoverFrame), _initialFirstCoverOrigin.y + offset, NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
            appRect = CGRectMake(NSMinX(_applicationView.frame), NSMinY(_applicationView.frame), NSWidth(_applicationView.frame), NSHeight(_initialApplicationViewFrame) + offset);
            if (NSMaxY(firstCoverFrame) >= 0 && NSHeight(appRect) >= self.toggleSizeMin.height) {
                _applicationView.frame = appRect;
                _applicationFirstCoverView.layer.frame = firstCoverFrame;
            }
            break;
        }
        case CNToggleEdgeLeft: {
            offset = location.x - _initialDraggingPoint.x;
            firstCoverFrame = CGRectMake(_initialFirstCoverOrigin.x + offset, NSMinY(firstCoverFrame), NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
            appRect = CGRectMake(NSMinX(_applicationView.frame), NSMinY(_applicationView.frame), NSWidth(_initialApplicationViewFrame) + offset, NSHeight(_applicationView.frame));
            if (NSMinX(firstCoverFrame) >= 0 && NSWidth(appRect) >= self.toggleSizeMin.width) {
                _applicationView.frame = appRect;
                _applicationFirstCoverView.layer.frame = firstCoverFrame;
            }
            break;
        }
        case CNToggleEdgeRight: {
            offset = location.x - _initialDraggingPoint.x;
            firstCoverFrame = CGRectMake(_initialFirstCoverOrigin.x + offset, NSMinY(firstCoverFrame), NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
            appRect = CGRectMake(NSMaxX(firstCoverFrame) + 1, NSMinY(_applicationView.frame), NSWidth(_initialApplicationViewFrame) - offset, NSHeight(_applicationView.frame));
            if (NSMinX(firstCoverFrame) <= 0 && NSWidth(appRect) >= self.toggleSizeMin.width) {
                _applicationView.frame = appRect;
                _applicationFirstCoverView.layer.frame = firstCoverFrame;
            }
            break;
        }
        case CNToggleEdgeSplitHorizontal: {
            offset = location.x - _initialDraggingPoint.x;
            if (NSPointInRect(location, firstCoverFrame)) {
                firstCoverFrame = CGRectMake(_initialFirstCoverOrigin.x + offset, NSMinY(firstCoverFrame), NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
                secondCoverFrame = CGRectMake(_initialSecondCoverOrigin.x - offset, NSMinY(secondCoverFrame), NSWidth(secondCoverFrame), NSHeight(secondCoverFrame));
            } else {
                firstCoverFrame = CGRectMake(_initialFirstCoverOrigin.x - offset, NSMinY(firstCoverFrame), NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
                secondCoverFrame = CGRectMake(_initialSecondCoverOrigin.x + offset, NSMinY(secondCoverFrame), NSWidth(secondCoverFrame), NSHeight(secondCoverFrame));
            }
            appRect = CGRectMake(NSMaxX(firstCoverFrame) - 1, NSMinY(_applicationView.frame), NSMinX(secondCoverFrame) - NSMaxX(firstCoverFrame) + 1, NSHeight(_applicationView.frame));
            if (NSMaxX(firstCoverFrame) >= 0 && NSMinX(firstCoverFrame) <= 0 && NSWidth(appRect) >= self.toggleSizeMin.width) {
                _applicationView.frame = appRect;
                _applicationFirstCoverView.layer.frame = firstCoverFrame;
                _applicationSecondCoverView.layer.frame = secondCoverFrame;
            }
            break;
        }
        case CNToggleEdgeSplitVertical: {
            offset = location.y - _initialDraggingPoint.y;
            if (NSPointInRect(location, firstCoverFrame)) {
                firstCoverFrame = CGRectMake(NSMinX(firstCoverFrame), _initialFirstCoverOrigin.y + offset, NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
                secondCoverFrame = CGRectMake(NSMinX(secondCoverFrame), _initialSecondCoverOrigin.y - offset, NSWidth(secondCoverFrame), NSHeight(secondCoverFrame));
            } else {
                firstCoverFrame = CGRectMake(NSMinX(firstCoverFrame), _initialFirstCoverOrigin.y - offset, NSWidth(firstCoverFrame), NSHeight(firstCoverFrame));
                secondCoverFrame = CGRectMake(NSMinX(secondCoverFrame), _initialSecondCoverOrigin.y + offset, NSWidth(secondCoverFrame), NSHeight(secondCoverFrame));
            }
            appRect = CGRectMake(NSMinX(_applicationView.frame), NSMaxY(secondCoverFrame) - 1, NSWidth(_applicationView.frame), NSMinY(firstCoverFrame) - NSMaxY(secondCoverFrame) + 1);
            if (NSMinY(secondCoverFrame) <= 0 && NSHeight(appRect) >= self.toggleSizeMin.height) {
                _applicationView.frame = appRect;
                _applicationFirstCoverView.layer.frame = firstCoverFrame;
                _applicationSecondCoverView.layer.frame = secondCoverFrame;
            }
            break;
        }
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSResponder

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (_applicationCoverIsDragging == NO) {
        /// inform the delegate
        [self backstageController:self willDragOnScreen:[self screenOfCurrentToggleDisplay] toggleEdge:self.toggleEdge];
    }
    [self dragCoverageUsingAnchorPoint:[theEvent locationInWindow]];
}

- (void)mouseDown:(NSEvent *)theEvent
{
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (!NSPointInRect([theEvent locationInWindow], [_applicationView frame])) {
        if (_applicationCoverIsDragging == NO) {
            [self collapse];
        } else {
            _applicationCoverIsDragging = NO;
            _applicationFirstCoverView.frame = _applicationFirstCoverView.layer.frame;
            _applicationSecondCoverView.frame = _applicationSecondCoverView.layer.frame;

            /// inform the delegate
            [self backstageController:self didDragOnScreen:[self screenOfCurrentToggleDisplay] toggleEdge:self.toggleEdge];
        }
    }
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    if (!NSPointInRect([theEvent locationInWindow], [_applicationView frame])) {
        [self collapse];
    }
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
    if (!NSPointInRect([theEvent locationInWindow], [_applicationView frame])) {
        [self collapse];
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSNotification

- (void)willResignActive:(NSNotification *)notification
{
    if ([self currentViewState] == CNToggleStateExpanded) {
        [self collapse];
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstage Delegate Callbacks

- (void)backstageController:(CNBackstageController *)backstageController willExpandOnScreen:(NSScreen *)toggleScreen toggleEdge:(CNToggleEdge)toggleEdge
{
    [_nc postNotificationName:CNBackstageControllerWillExpandOnScreenNotification
                      object:backstageController
                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                              toggleScreen, CNToggleScreenUserInfoKey,
                              [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                              nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController willExpandOnScreen:toggleScreen toggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController didExpandOnScreen:(NSScreen *)toggleScreen toggleEdge:(CNToggleEdge)toggleEdge
{
    [_nc postNotificationName:CNBackstageControllerDidExpandOnScreenNotification
                      object:backstageController
                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                              toggleScreen, CNToggleScreenUserInfoKey,
                              [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                              nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController didExpandOnScreen:toggleScreen toggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController willCollapseOnScreen:(NSScreen *)toggleScreen toggleEdge:(CNToggleEdge)toggleEdge
{
    [_nc postNotificationName:CNBackstageControllerWillCollapseOnScreenNotification
                      object:backstageController
                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                              toggleScreen, CNToggleScreenUserInfoKey,
                              [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                              nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController willCollapseOnScreen:toggleScreen toggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController didCollapseOnScreen:(NSScreen *)toggleScreen toggleEdge:(CNToggleEdge)toggleEdge
{
    [_nc postNotificationName:CNBackstageControllerDidCollapseOnScreenNotification
                      object:backstageController
                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                              toggleScreen, CNToggleScreenUserInfoKey,
                              [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                              nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController didCollapseOnScreen:toggleScreen toggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController willDragOnScreen:(NSScreen *)toggleScreen toggleEdge:(CNToggleEdge)toggleEdge
{
    [_nc postNotificationName:CNBackstageControllerWillDragOnScreenNotification
                      object:backstageController
                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                              toggleScreen, CNToggleScreenUserInfoKey,
                              [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                              nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController willDragOnScreen:toggleScreen toggleEdge:toggleEdge];
    }
}

- (void)backstageController:(CNBackstageController *)backstageController didDragOnScreen:(NSScreen *)toggleScreen toggleEdge:(CNToggleEdge)toggleEdge
{
    [_nc postNotificationName:CNBackstageControllerDidDragOnScreenNotification
                      object:backstageController
                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                              toggleScreen, CNToggleScreenUserInfoKey,
                              [NSNumber numberWithInteger:toggleEdge], CNToggleEdgeUserInfoKey,
                              nil]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate backstageController:backstageController didDragOnScreen:toggleScreen toggleEdge:toggleEdge];
    }
}


@end



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Constants & Convenience Functions

const CGFloat kAnimationDuration = 0.25;
const uint32_t kMaxNumberOfSupportedDisplays = 16;

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
/// Convenience Functions

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

CGRect CNRectMake(NSScreen *currentScreen, CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
    return [currentScreen convertRectToBacking:CGRectMake(x, y, width, height)];
}


