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


#define kAnimationDuration  0.38

typedef struct {
    CGFloat deltaX;
    CGFloat deltaY;
} CNToggleFrameDeltas;


typedef enum {
    CNToggleStateClosed = -1,
    CNToggleStateOpened = 1
} CNToggleState;


@interface CNBackstageController()
@property (strong) NSViewController <CNBackstageDelegate, CNBackstageDataSource> *applicationViewController;
@property (strong) NSView *applicationView;



@property (nonatomic, strong) NSView *finderSnapshotView;
@property (nonatomic, strong) NSView *finderSnapshotViewOverlay;
@property (nonatomic, assign) BOOL hasLayerHierarchy;

@property (nonatomic, assign) CNToggleState toggleState;
@property (nonatomic, strong) NSApplication *sharedApplication;
@property (nonatomic, assign) BOOL dockIsHidden;
@property (nonatomic, assign) BOOL iAmToggling;
@property (nonatomic, assign, getter = isNibInstanced) BOOL nibInstanced;
@property (nonatomic, readonly) CGRect toggleDisplayFrame;


- (void)toggleViewStateOpen;
- (void)toggleViewStateClose;
- (void)initializeApplicationWindow;
- (void)buildLayerHierarchy;
- (NSRect)frameForApplicationView;
- (void)goOnStage;
- (void)goOffStage;
- (void)toggleDisplayEffectOn;
- (void)toggleDisplayEffectOff;
- (CNToggleFrameDeltas)toggleDeltasForFrame:(NSRect)aFrame;
- (float)valueForToggleSize:(NSInteger)aToggleSize frameSize:(CGFloat)aSize;
- (NSScreen*)toggleScreen;
- (CGRect)toggleDisplayFrame;
- (void)hideDock;
- (void)showDock;
- (CGDirectDisplayID)displayIDForToggleDisplay:(CNToggleDisplay)aToggleDisplay;
- (NSScreen*)screenWithDisplayID:(CGDirectDisplayID)displayID;
- (CGImageRef)snapshotOfDisplayWithID:(CGDirectDisplayID)displayID;
- (CGRect)movableFrameOfScreenWithID:(CGDirectDisplayID)displayID;
- (int)systemStatusBarThickness;
@end


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
        _toggleDisplayEffect            = CNToggleDisplayEffectBlackOverlay;
        _applicationViewBehavior        = CNApplicationViewBehaviorStatic;
        _finderSnapshotView             = [[NSView alloc] init];
        _finderSnapshotViewOverlay      = [[NSView alloc] init];
        _applicationView                = [[NSView alloc] init];
        _iAmToggling                    = NO;
        _dockIsHidden                   = NO;
        _hasLayerHierarchy              = NO;
        _nibInstanced                   = NO;
        _sharedApplication              = [NSApplication sharedApplication];
        _applicationView                = nil;
        _applicationViewController      = nil;
    }
    return self;
}

- (id)initWithApplicationViewController:(NSViewController <CNBackstageDelegate, CNBackstageDataSource> *)applicationViewController
{
    self = [self init];
    if (self) {
        _delegate = applicationViewController;
        _dataSource = applicationViewController;
        _applicationViewController = applicationViewController;
        _applicationView = _applicationViewController.view;
    }
    return self;
}



/**
 Steps on toggling:
 
 Toggle ON:
 [01] make screenshot
 [02] init app window
 [03] init views/subviews:
        • window.contentView -> root background view
        • window.contentView.subview[0] -> view of applicationViewController
        • window.contentView.subview[1] -> finder snapshot view
        • window.contentView.subview[1].subview[0] -> finder snapshow view, transparent black overlay
        • window.contentView.subview[1].subView[1] -> border line
 */



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public API

- (void)toggleViewState
{
    if (self.iAmToggling == NO) {
        self.iAmToggling = YES;

        [NSApp activateIgnoringOtherApps:YES];

        /// make a screenshot

        /// inform the delegate
        [self screen:self.toggleScreen willToggleOnEdge:self.toggleEdge];
        
        switch (self.toggleState) {
            case CNToggleStateClosed: [self toggleViewStateOpen]; break;
            case CNToggleStateOpened: [self toggleViewStateClose]; break;
        }

        /// inform the delegate
        [self screen:self.toggleScreen didToggleOnEdge:self.toggleEdge];
    }
}




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private API

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


















































// --------------------------------------------------------------------------------------------------------------------------
#pragma mark - Accessors
// --------------------------------------------------------------------------------------------------------------------------

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




// --------------------------------------------------------------------------------------------------------------------------
#pragma mark - Public API
// --------------------------------------------------------------------------------------------------------------------------


// --------------------------------------------------------------------------------------------------------------------------
#pragma mark - Private Helper
// --------------------------------------------------------------------------------------------------------------------------

- (void)toggleViewStateOpen
{
    [self initializeApplicationWindow];
    [self buildLayerHierarchy];
    
    [self goOnStage];
    [self hideDock];
    
    switch (self.applicationViewBehavior) {
        case CNApplicationViewBehaviorFade:
            self.applicationView.alphaValue = 0.0;
            break;

        default:
            break;
    }

    __block NSRect applicationFrame = self.applicationView.frame;
    __block NSRect snapshotFrame = self.finderSnapshotView.frame;
    [self.applicationView setNeedsLayout:YES];
    [self.finderSnapshotView setNeedsLayout:YES];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        switch (self.applicationViewBehavior) {
            case CNApplicationViewBehaviorSlide:
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
                break;

            case CNApplicationViewBehaviorFade: {
                [[self.applicationView animator] setAlphaValue:1.0];
                break;
            }

            default:
                break;
        }

        // animate the snapshot layer
        switch (self.toggleEdge) {
            case CNToggleEdgeTop:               snapshotFrame.origin.y -= floor([self toggleDeltasForFrame:snapshotFrame].deltaY); break;
            case CNToggleEdgeBottom:            snapshotFrame.origin.y += floor([self toggleDeltasForFrame:snapshotFrame].deltaY); break;
            case CNToggleEdgeLeft:              snapshotFrame.origin.x += floor([self toggleDeltasForFrame:snapshotFrame].deltaX); break;
            case CNToggleEdgeRight:             snapshotFrame.origin.x -= floor([self toggleDeltasForFrame:snapshotFrame].deltaX); break;
            case CNToggleEdgeSplitHorizontal:
                break;
            case CNToggleEdgeSplitVertical:
                break;
        }

        [self toggleDisplayEffectOn];
        [[self.finderSnapshotView animator] setFrame:snapshotFrame];
        [[self.applicationView animator] setFrame:applicationFrame];

        
    } completionHandler:^{
        self.toggleState = CNToggleStateOpened;
        self.iAmToggling = NO;
        CNLogForRect(self.applicationView.frame);
        CNLogForRect(self.applicationView.layer.frame);
    }];
}

- (void)toggleViewStateClose
{
    __block NSRect applicationFrame = self.applicationView.frame;
    __block NSRect snapshotFrame = self.finderSnapshotView.frame;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        switch (self.applicationViewBehavior) {
            case CNApplicationViewBehaviorSlide:
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
                break;

            case CNApplicationViewBehaviorFade: {
                [[self.applicationView animator] setAlphaValue:0.0];
                break;
            }
            default:
                break;
        }

        // animate the snapshot
        switch (self.toggleEdge) {
            case CNToggleEdgeTop:       snapshotFrame.origin.y += [self toggleDeltasForFrame:snapshotFrame].deltaY; break;
            case CNToggleEdgeBottom:    snapshotFrame.origin.y -= [self toggleDeltasForFrame:snapshotFrame].deltaY; break;
            case CNToggleEdgeLeft:      snapshotFrame.origin.x -= [self toggleDeltasForFrame:snapshotFrame].deltaX; break;
            case CNToggleEdgeRight:     snapshotFrame.origin.x += [self toggleDeltasForFrame:snapshotFrame].deltaX; break;
            default: break;
        }

        [self toggleDisplayEffectOff];
        [[self.applicationView animator] setFrame:applicationFrame];
        [[self.finderSnapshotView animator] setFrame:snapshotFrame];

        
    } completionHandler:^{
        [self showDock];
        [self goOffStage];
        self.iAmToggling = NO;
        self.toggleState = CNToggleStateClosed;
        CNLogForRect(self.applicationView.frame);
        CNLogForRect(self.applicationView.layer.frame);
    }];
}

- (void)buildLayerHierarchy
{
    self.applicationView.frame = [self frameForApplicationView];
    self.finderSnapshotView.frame = self.window.frame;
    
    if (self.hasLayerHierarchy == NO) {
        self.hasLayerHierarchy = YES;

        // Finder Snapshot Overlay
        [self.finderSnapshotView addSubview:self.finderSnapshotViewOverlay];
        CNBackstageView *shadowView = [[CNBackstageView alloc] initWithFrame:self.finderSnapshotView.frame];
        shadowView.toggleEdge = self.toggleEdge;
        [self.finderSnapshotView addSubview:shadowView];

        // Application
        [[self.window contentView] addSubview:self.applicationView];
        
        // Finder Snapshot
        [[self.window contentView] addSubview:self.finderSnapshotView];
    }
}

- (NSRect)frameForApplicationView
{
    NSRect resultRect = NSZeroRect;
    switch (self.toggleEdge) {
        case CNToggleEdgeTop:
            resultRect.size = NSMakeSize(self.window.frame.size.width, [self toggleDeltasForFrame:self.window.frame].deltaY);
            resultRect.origin.x  = 0;
            switch (self.applicationViewBehavior) {
                case CNApplicationViewBehaviorFade:
                case CNApplicationViewBehaviorStatic:
                    resultRect.origin.y = self.window.frame.size.height - resultRect.size.height;
                    break;
                    
                case CNApplicationViewBehaviorSlide:
                    resultRect.origin.y = self.window.frame.size.height;
                    break;
            }
            break;
            
        case CNToggleEdgeBottom:
            resultRect.size = NSMakeSize(self.window.frame.size.width, [self toggleDeltasForFrame:self.window.frame].deltaY);
            resultRect.origin.x  = 0;
            switch (self.applicationViewBehavior) {
                case CNApplicationViewBehaviorFade:
                case CNApplicationViewBehaviorStatic:
                    resultRect.origin.y = 0;
                    break;
                    
                case CNApplicationViewBehaviorSlide:
                    resultRect.origin.y = 0 - resultRect.size.height;
                    break;
            }
            break;
            
        case CNToggleEdgeLeft:
            resultRect.size = NSMakeSize([self toggleDeltasForFrame:self.window.frame].deltaX, self.window.frame.size.height);
            resultRect.origin.x  = 0;
            resultRect.origin.y  = 0;
            switch (self.applicationViewBehavior) {
                case CNApplicationViewBehaviorFade:
                case CNApplicationViewBehaviorStatic:
                    resultRect.origin.x = 0;
                    break;
                    
                case CNApplicationViewBehaviorSlide:
                    resultRect.origin.x = 0 - resultRect.size.width;
                    break;
            }
            break;
            
        case CNToggleEdgeRight:
            resultRect.size = NSMakeSize([self toggleDeltasForFrame:self.window.frame].deltaX, self.window.frame.size.height);
            resultRect.origin.x  = self.window.frame.size.width - resultRect.size.width;
            resultRect.origin.y  = 0;
            switch (self.applicationViewBehavior) {
                case CNApplicationViewBehaviorFade:
                case CNApplicationViewBehaviorStatic:
                    resultRect.origin.x = self.window.frame.size.width - resultRect.size.width;
                    break;
                    
                case CNApplicationViewBehaviorSlide:
                    resultRect.origin.x = self.window.frame.size.width;
                    break;
            }
            break;
    }
    return resultRect;
}

- (void)goOnStage
{
    CGDirectDisplayID displayID = [self displayIDForToggleDisplay:self.toggleDisplay];
    NSRect contentViewBounds = [self.window.contentView bounds];
    
    CGImageRef snapshotRef = [self snapshotOfDisplayWithID:displayID];
    self.finderSnapshotView.frame = contentViewBounds;
    self.finderSnapshotView.layer.contents = (__bridge id)(snapshotRef);
    CGImageRelease(snapshotRef);
    
    self.finderSnapshotViewOverlay.frame = contentViewBounds;
    self.finderSnapshotViewOverlay.layer.opaque = NO;
    self.finderSnapshotViewOverlay.layer.opacity = 0.0;

    [self showWindow:nil];
}

- (void)goOffStage
{
    self.finderSnapshotView.layer.contents = nil;
    [self.window close];
    self.window = [NSWindow new];
}

- (CGImageRef)snapshotOfDisplayWithID:(CGDirectDisplayID)displayID
{
    return CGDisplayCreateImageForRect(displayID, [self movableFrameOfScreenWithID:displayID]);
}

- (int)systemStatusBarThickness
{
    return ([self displayIDForToggleDisplay:self.toggleDisplay] == CGMainDisplayID() ? [[NSStatusBar systemStatusBar] thickness] : 0);
}

- (CNToggleFrameDeltas)toggleDeltasForFrame:(NSRect)aFrame
{
    CNToggleFrameDeltas frameDeltas;
    switch (self.toggleEdge) {
        case CNToggleEdgeTop:
        case CNToggleEdgeBottom:
            frameDeltas.deltaX = 0;
            switch (self.toggleSize) {
                case CNToggleSizeHalfScreen:
                case CNToggleSizeQuarterScreen:
                case CNToggleSizeThreeQuarterScreen:
                case CNToggleSizeOneThirdScreen:
                case CNToggleSizeTwoThirdsScreen:
                    frameDeltas.deltaY = [self valueForToggleSize:self.toggleSize frameSize:aFrame.size.height];
                    break;
                default:
                    frameDeltas.deltaY = self.toggleSize;
                    break;
            }
            break;
            
        case CNToggleEdgeLeft:
        case CNToggleEdgeRight:
            frameDeltas.deltaY = 0;
            switch (self.toggleSize) {
                case CNToggleSizeHalfScreen:
                case CNToggleSizeQuarterScreen:
                case CNToggleSizeThreeQuarterScreen:
                case CNToggleSizeOneThirdScreen:
                case CNToggleSizeTwoThirdsScreen:
                    frameDeltas.deltaX = [self valueForToggleSize:self.toggleSize frameSize:aFrame.size.width]; 
                    break;
                default:
                    frameDeltas.deltaX = self.toggleSize;
                    break;
            }
            break;
    }
    return frameDeltas;
}

- (void)toggleDisplayEffectOn
{
    if (self.toggleDisplayEffect & CNToggleDisplayEffectBlackOverlay) {
        self.finderSnapshotViewOverlay.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
        [[self.finderSnapshotViewOverlay animator] setAlphaValue:0.75];
    }
}

- (void)toggleDisplayEffectOff
{
    if (self.toggleDisplayEffect & CNToggleDisplayEffectBlackOverlay) {
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

- (float)valueForToggleSize:(NSInteger)aToggleSize frameSize:(CGFloat)aSize
{
    float value = 0;
    switch (aToggleSize) {
        case CNToggleSizeHalfScreen:            value = aSize /  -2.00 * -1; break;
        case CNToggleSizeQuarterScreen:         value = aSize /  -4.00 * -1; break;
        case CNToggleSizeThreeQuarterScreen:    value = aSize * (-0.75 * -1); break;
        case CNToggleSizeOneThirdScreen:        value = aSize /  -3.00 * -1; break;
        case CNToggleSizeTwoThirdsScreen:       value = aSize /  -1.50 * -1; break;
    }
    return value;
}

- (void)hideDock
{
    if ([self.toggleScreen containsDock]) {
        self.sharedApplication.presentationOptions = NSApplicationPresentationHideDock;
        self.dockIsHidden = YES;
    }
}

- (void)showDock
{
    if (self.dockIsHidden) {
        self.sharedApplication.presentationOptions = NSApplicationPresentationDefault;
        self.dockIsHidden = NO;
    }
}

- (CGDirectDisplayID)displayIDForToggleDisplay:(CNToggleDisplay)aToggleDisplay
{
    uint32_t MAX_TOGGLE_DISPLAYS = 4;   // number of supported displays
    
    uint32_t displayCount;
    CGDirectDisplayID toggleDisplays[MAX_TOGGLE_DISPLAYS];
    CGDirectDisplayID returnValue;
    
    CGGetOnlineDisplayList(MAX_TOGGLE_DISPLAYS, toggleDisplays, &displayCount);
    if (aToggleDisplay > displayCount) {
        returnValue = toggleDisplays[0];
    } else {
        returnValue = toggleDisplays[aToggleDisplay];
    }
    return returnValue;
}

- (CGRect)movableFrameOfScreenWithID:(CGDirectDisplayID)displayID
{
    return CGRectMake(0, 0 + self.systemStatusBarThickness,
                      self.toggleDisplayFrame.size.width,
                      self.toggleDisplayFrame.size.height - self.systemStatusBarThickness);
}

- (NSScreen*)screenWithDisplayID:(CGDirectDisplayID)displayID {
    NSScreen *result;
    for (NSScreen *aScreen in [NSScreen screens]) {
        if ([[[aScreen deviceDescription] valueForKey:@"NSScreenNumber"] intValue] == displayID) {
            result = aScreen;
            break;
        }
    }
    return result;
}

@end




@implementation CNBackstageView

- (void)setToggleEdge:(CNToggleEdge)toggleEdge
{
    _toggleEdge = toggleEdge;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    //// Color Declarations
    NSColor *startColor = [[NSColor blackColor] colorWithAlphaComponent:0.42];
    NSColor *endColor = [NSColor clearColor];

    CGRect gradientRect = NSZeroRect;
    CGFloat angle = 0;
    switch (self.toggleEdge) {
        case CNToggleEdgeTop:       gradientRect = NSMakeRect(0, NSHeight(dirtyRect)-12, NSWidth(dirtyRect), 11); angle = -90; break;
        case CNToggleEdgeRight:     gradientRect = NSMakeRect(NSWidth(dirtyRect)-12, 0, 11, NSHeight(dirtyRect)); angle = 180; break;
        case CNToggleEdgeBottom:    gradientRect = NSZeroRect; angle = 90; break;
        case CNToggleEdgeLeft:      gradientRect = NSMakeRect(0, 0, 11, NSHeight(dirtyRect));  angle = 0; break;
        default: break;
    }

    //// Gradient Declarations
    NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations: startColor, 0.0, endColor, 1.0, nil];

    //// Rectangle Drawing
    NSBezierPath *gradienPath = [NSBezierPath bezierPathWithRect:gradientRect];
    [gradient drawInBezierPath:gradienPath angle:angle];
}

@end

