//
//  CNBackstageShadowView.m
//
//  Created by cocoa:naut on 09.11.12.
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

#import "CNBackstageShadowView.h"


const CGFloat shadowOffset = 3;

static NSColor *darkLineColor, *brightLineColor;
static NSColor *shadowRectColor, *shadowColorNormal, *shadowColorLighter, *shadowColorDarker;
static NSShadow *edgeShadow;
static NSSize shadowOffsetTop, shadowOffsetLeft, shadowOffsetRight;

@implementation CNBackstageShadowView

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization

+ (void)initialize
{
    darkLineColor = [NSColor colorWithCalibratedWhite:0.000 alpha:0.500];
    brightLineColor = [NSColor colorWithDeviceRed:1.000 green:1.000 blue:1.000 alpha:0.300];
    shadowRectColor = [NSColor blackColor];
    shadowColorNormal = [NSColor colorWithCalibratedWhite:0.000 alpha:0.550];
    shadowColorLighter = [NSColor colorWithCalibratedWhite:0.000 alpha:0.350];
    shadowColorDarker = [NSColor colorWithCalibratedWhite:0.000 alpha:0.750];
    edgeShadow = [[NSShadow alloc] init];
    [edgeShadow setShadowBlurRadius:11.0f];
    [edgeShadow setShadowColor:shadowColorNormal];
    shadowOffsetTop = NSMakeSize(0, -shadowOffset);
    shadowOffsetLeft = NSMakeSize(shadowOffset, 0);
    shadowOffsetRight = NSMakeSize(-shadowOffset, 0);
}

- (id)init
{
    self = [super init];
    if (self) {
        _shouldUseShadows = YES;
        _shadowIntensity = CNShadowIntensityNormal;
    }
    return self;
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors

- (void)setShadowIntensity:(CNShadowIntensity)shadowIntensity
{
    if (_shadowIntensity != shadowIntensity) {
        _shadowIntensity = shadowIntensity;
        switch (_shadowIntensity) {
            case CNShadowIntensityNormal:   [edgeShadow setShadowColor:shadowColorNormal]; break;
            case CNShadowIntensityLighter:  [edgeShadow setShadowColor:shadowColorLighter]; break;
            case CNShadowIntensityDarker:   [edgeShadow setShadowColor:shadowColorDarker]; break;
        }
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSView

- (void)drawRect:(NSRect)dirtyRect
{
    switch (self.toggleEdge) {
        case CNToggleEdgeTop: {
            if (self.shouldUseShadows) {
                [edgeShadow setShadowOffset:shadowOffsetTop];
                [edgeShadow set];
                NSRect topRect = NSMakeRect(NSMinX(dirtyRect)-5, NSHeight(dirtyRect), NSWidth(dirtyRect)+10, 15);
                NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
                [shadowRectColor setFill];
                [topPath fill];
            }
            NSRect bottomRect = NSMakeRect(NSMinX(dirtyRect), ceil(NSMinY(dirtyRect)), NSWidth(dirtyRect), 1);
            NSBezierPath *bottomPath = [NSBezierPath bezierPathWithRect:bottomRect];
            [brightLineColor setFill];
            [bottomPath fill];
            break;
        }
        case CNToggleEdgeRight: {
            if (self.shouldUseShadows) {
                [edgeShadow setShadowOffset:shadowOffsetTop];
                [edgeShadow set];
                NSRect topRect = NSMakeRect(NSMinX(dirtyRect), NSHeight(dirtyRect), NSWidth(dirtyRect)+5, 15);
                NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
                [shadowRectColor setFill];
                [topPath fill];

                [edgeShadow setShadowOffset:shadowOffsetLeft];
                [edgeShadow set];
                NSRect leftRect = NSMakeRect(floor(NSMinX(dirtyRect))-10, NSMinY(dirtyRect)-5, 10, NSHeight(dirtyRect)+5);
                NSBezierPath *leftPath = [NSBezierPath bezierPathWithRect:leftRect];
                [shadowRectColor setFill];
                [leftPath fill];
            }
            NSRect leftLineRect = NSMakeRect(ceil(NSMinX(dirtyRect)), NSMinY(dirtyRect), 1, NSHeight(dirtyRect));
            NSBezierPath *leftLinePath = [NSBezierPath bezierPathWithRect:leftLineRect];
            [darkLineColor setFill];
            [leftLinePath fill];
            break;
        }
        case CNToggleEdgeBottom: {
            if (self.shouldUseShadows) {
                [edgeShadow setShadowOffset:shadowOffsetTop];
                [edgeShadow set];
                NSRect topRect = NSMakeRect(NSMinX(dirtyRect)-5, ceil(NSMaxY(dirtyRect))-1, NSWidth(dirtyRect)+10, 15);
                NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
                [shadowRectColor setFill];
                [topPath fill];
            }
            NSRect topLineRect = NSMakeRect(NSMinX(dirtyRect), ceil(NSMaxY(dirtyRect)), NSWidth(dirtyRect), 1);
            NSBezierPath *topLinePath = [NSBezierPath bezierPathWithRect:topLineRect];
            [darkLineColor setFill];
            [topLinePath fill];
            break;
        }
        case CNToggleEdgeLeft: {
            if (self.shouldUseShadows) {
                [edgeShadow setShadowOffset:shadowOffsetTop];
                [edgeShadow set];
                NSRect topRect = NSMakeRect(NSMinX(dirtyRect), NSHeight(dirtyRect), NSWidth(dirtyRect)+5, 15);
                NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
                [shadowRectColor setFill];
                [topPath fill];

                [edgeShadow setShadowOffset:shadowOffsetRight];
                [edgeShadow set];
                NSRect rightRect = NSMakeRect(ceil(NSMaxX(dirtyRect)), NSMinY(dirtyRect)-5, 10, NSHeight(dirtyRect)+5);
                NSBezierPath *rightPath = [NSBezierPath bezierPathWithRect:rightRect];
                [shadowRectColor setFill];
                [rightPath fill];
            }
            NSRect rightLineRect = NSMakeRect(ceil(NSWidth(dirtyRect))-1, NSMinY(dirtyRect)-5, 7, NSHeight(dirtyRect)+10);
            NSBezierPath *rightLinePath = [NSBezierPath bezierPathWithRect:rightLineRect];
            [darkLineColor setFill];
            [rightLinePath fill];
            break;
        }
        case CNToggleEdgeSplitHorizontal: {
            if (self.shouldUseShadows) {
                [edgeShadow setShadowOffset:shadowOffsetLeft];
                [edgeShadow set];
                NSRect leftRect = NSMakeRect(floor(NSMinX(dirtyRect))-10, NSMinY(dirtyRect)-5, 10, NSHeight(dirtyRect)+5);
                NSBezierPath *leftPath = [NSBezierPath bezierPathWithRect:leftRect];
                [shadowRectColor setFill];
                [leftPath fill];

                [edgeShadow setShadowOffset:shadowOffsetRight];
                [edgeShadow set];
                NSRect rightRect = NSMakeRect(ceil(NSMaxX(dirtyRect)), NSMinY(dirtyRect)-5, 10, NSHeight(dirtyRect)+5);
                NSBezierPath *rightPath = [NSBezierPath bezierPathWithRect:rightRect];
                [shadowRectColor setFill];
                [rightPath fill];
            }
            NSRect leftLineRect = NSMakeRect(floor(NSMinX(dirtyRect))+1, NSMinY(dirtyRect), 1, NSHeight(dirtyRect));
            NSBezierPath *leftLinePath = [NSBezierPath bezierPathWithRect:leftLineRect];
            [darkLineColor setFill];
            [leftLinePath fill];

            NSRect rightLineRect = NSMakeRect(NSMaxX(dirtyRect)-1, NSMinY(dirtyRect), 1, NSHeight(dirtyRect));
            NSBezierPath *lineLinePath = [NSBezierPath bezierPathWithRect:rightLineRect];
            [darkLineColor setFill];
            [lineLinePath fill];
            break;
        }
        case CNToggleEdgeSplitVertical: {
            if (self.shouldUseShadows) {
                [edgeShadow setShadowOffset:shadowOffsetTop];
                [edgeShadow set];
                NSRect topRect = NSMakeRect(NSMinX(dirtyRect)-5, NSHeight(dirtyRect), NSWidth(dirtyRect)+10, 15);
                NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
                [shadowRectColor setFill];
                [topPath fill];
            }
            NSRect topLineRect = NSMakeRect(NSMinX(dirtyRect), floor(NSMaxY(dirtyRect))-1, NSWidth(dirtyRect), 1);
            NSBezierPath *topLinePath = [NSBezierPath bezierPathWithRect:topLineRect];
            [darkLineColor setFill];
            [topLinePath fill];

            NSRect bottomLineRect = NSMakeRect(NSMinX(dirtyRect), ceil(NSMinY(dirtyRect))+1, NSWidth(dirtyRect), 1);
            NSBezierPath *bottomLinePath = [NSBezierPath bezierPathWithRect:bottomLineRect];
            [brightLineColor setFill];
            [bottomLinePath fill];
            break;
        }
    }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CALayer

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
