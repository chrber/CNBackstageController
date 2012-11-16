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

static NSColor *darkLineColor, *brightLineColor, *shadowColor;
static NSShadow *edgeShadow;

@implementation CNBackstageShadowView

+ (void)initialize
{
    darkLineColor = [NSColor colorWithCalibratedRed:0.046 green:0.047 blue:0.047 alpha:1.000];
    brightLineColor = [NSColor colorWithDeviceRed:0.679 green:0.698 blue:0.698 alpha:1.000];
    shadowColor = [NSColor colorWithCalibratedRed:0.f green:0.f blue:0.f alpha:0.75];
    edgeShadow = [[NSShadow alloc] init];
    [edgeShadow setShadowBlurRadius:13.0f];
    [edgeShadow setShadowColor:shadowColor];
}

- (id)init
{
    self = [super init];
    if (self) {
        _useShadows = YES;
    }
    return self;
}

- (void)setToggleEdge:(CNToggleEdge)toggleEdge
{
    _toggleEdge = toggleEdge;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    switch (self.toggleEdge) {
        case CNToggleEdgeTop: {
            NSRect topRect = NSMakeRect(NSMinX(dirtyRect)-5, NSHeight(dirtyRect), NSWidth(dirtyRect)+10, 15);
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];

            if (self.useShadows) {
                [edgeShadow setShadowOffset:NSMakeSize(0, -3)];
                [edgeShadow set];
            }
            [darkLineColor setFill];
            [topPath fill];

            NSRect leftRect = NSMakeRect(ceil(NSMinX(dirtyRect))-10, NSMinY(dirtyRect)-5, 10, NSHeight(dirtyRect)+10);
            NSBezierPath *leftPath = [NSBezierPath bezierPathWithRect:leftRect];

            if (self.useShadows) {
                [edgeShadow setShadowOffset:NSMakeSize(3, 0)];
                [edgeShadow set];
            }
            [darkLineColor setFill];
            [leftPath fill];

            NSRect bottomRect = NSMakeRect(NSMinX(dirtyRect), floor(NSMinY(dirtyRect)), NSWidth(dirtyRect), 1);
            NSBezierPath *bottomPath = [NSBezierPath bezierPathWithRect:bottomRect];
            [brightLineColor setFill];
            [bottomPath fill];
            break;
        }
        case CNToggleEdgeRight: {
            NSRect leftRect = NSMakeRect(ceil(NSMinX(dirtyRect))-10, NSMinY(dirtyRect)-5, 11, NSHeight(dirtyRect)+5);
            NSBezierPath *leftPath = [NSBezierPath bezierPathWithRect:leftRect];

            if (self.useShadows) {
                [edgeShadow setShadowOffset:NSMakeSize(3, 0)];
                [edgeShadow set];
            }
            [darkLineColor setFill];
            [leftPath fill];

            NSRect topRect = NSMakeRect(NSMinX(dirtyRect), NSHeight(dirtyRect), NSWidth(dirtyRect)+5, 15);
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
            if (self.useShadows) {
                [edgeShadow setShadowOffset:NSMakeSize(0, -3)];
                [edgeShadow set];
            }
            [darkLineColor setFill];
            [topPath fill];
            break;
        }
        case CNToggleEdgeBottom: {
            NSRect topRect = NSMakeRect(NSMinX(dirtyRect)-5, ceil(NSMaxY(dirtyRect))-1, NSWidth(dirtyRect)+10, 15);
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];

            if (self.useShadows) {
                [edgeShadow setShadowOffset:NSMakeSize(0, -3)];
                [edgeShadow set];
            }
            [darkLineColor setFill];
            [topPath fill];

            NSRect leftRect = NSMakeRect(floor(NSMinX(dirtyRect))-10, NSMinY(dirtyRect)-5, 10, NSHeight(dirtyRect)+5);
            NSBezierPath *leftPath = [NSBezierPath bezierPathWithRect:leftRect];
            if (self.useShadows) {
                [edgeShadow setShadowOffset:NSMakeSize(3, 0)];
                [edgeShadow set];
            }
            [darkLineColor setFill];
            [leftPath fill];
            break;
        }
        case CNToggleEdgeLeft: {
            NSRect rightRect = NSMakeRect(ceil(NSWidth(dirtyRect))-1, NSMinY(dirtyRect)-5, 7, NSHeight(dirtyRect)+10);
            NSBezierPath *rightPath = [NSBezierPath bezierPathWithRect:rightRect];
            [brightLineColor setFill];
            [rightPath fill];

            NSRect leftRect = NSMakeRect(floor(NSMinX(dirtyRect))-10, NSMinY(dirtyRect)-5, 10, NSHeight(dirtyRect)+5);
            NSBezierPath *leftPath = [NSBezierPath bezierPathWithRect:leftRect];
            if (self.useShadows) {
                [edgeShadow setShadowOffset:NSMakeSize(3, 0)];
                [edgeShadow set];
            }
            [darkLineColor setFill];
            [leftPath fill];

            NSRect topRect = NSMakeRect(NSMinX(dirtyRect), NSHeight(dirtyRect), NSWidth(dirtyRect)+5, 15);
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
            if (self.useShadows) {
                [edgeShadow setShadowOffset:NSMakeSize(0, -3)];
                [edgeShadow set];
            }
            [darkLineColor setFill];
            [topPath fill];
            break;
        }
        case CNToggleEdgeSplitHorizontal: {
            NSRect leftRect = NSMakeRect(floor(NSMinX(dirtyRect))-9, NSMinY(dirtyRect)-5, 11, NSHeight(dirtyRect)+5);
            NSBezierPath *linePath = [NSBezierPath bezierPathWithRect:leftRect];
            if (self.useShadows) {
                [edgeShadow setShadowOffset:NSMakeSize(3, 0)];
                [edgeShadow set];
            }
            [darkLineColor setFill];
            [linePath fill];

            NSRect topRect = NSMakeRect(NSMinX(dirtyRect), NSHeight(dirtyRect), NSWidth(dirtyRect)+5, 15);
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
            if (self.useShadows) {
                [edgeShadow setShadowOffset:NSMakeSize(0, -3)];
                [edgeShadow set];
            }
            [darkLineColor setFill];
            [topPath fill];

            NSRect rightRect = NSMakeRect(NSMaxX(dirtyRect)-1, NSMinY(dirtyRect), 1, NSHeight(dirtyRect));
            linePath = [NSBezierPath bezierPathWithRect:rightRect];
            [brightLineColor setFill];
            [linePath fill];
            break;
        }
        case CNToggleEdgeSplitVertical: {
            NSRect topRect = NSMakeRect(NSMinX(dirtyRect)-5, floor(NSHeight(dirtyRect))-1, NSWidth(dirtyRect)+10, 15);
            NSBezierPath *topPath = [NSBezierPath bezierPathWithRect:topRect];
            if (self.useShadows) {
                [edgeShadow setShadowOffset:NSMakeSize(0, -3)];
                [edgeShadow set];
            }
            [darkLineColor setFill];
            [topPath fill];

            NSRect leftRect = NSMakeRect(floor(NSMinX(dirtyRect))-10, NSMinY(dirtyRect)-5, 10, NSHeight(dirtyRect)+5);
            NSBezierPath *leftPath = [NSBezierPath bezierPathWithRect:leftRect];
            if (self.useShadows) {
                [edgeShadow setShadowOffset:NSMakeSize(3, 0)];
                [edgeShadow set];
            }
            [darkLineColor setFill];
            [leftPath fill];

            NSRect lineBottomRect = NSMakeRect(NSMinX(dirtyRect), ceil(NSMinY(dirtyRect))+1, NSWidth(dirtyRect), 1);
            NSBezierPath *lineBottomPath = [NSBezierPath bezierPathWithRect:lineBottomRect];
            [brightLineColor setFill];
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
