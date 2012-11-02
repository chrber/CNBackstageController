//
//  CNApplicationViewController.m
//  CNBackstageController Example
//
//  Created by cocoa:naut on 01.11.12.
//  Copyright (c) 2012 cocoa:naut. All rights reserved.
//

#import "CNApplicationViewController.h"


@implementation CNApplicationViewController

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions

- (IBAction)buttonAction:(id)sender
{

}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstage Delegate

- (void)screen:(NSScreen *)toggleScreen willToggleOnEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"screen: %@ -- willToggleOnEdge: %i", toggleScreen, toggleEdge);
}

- (void)screen:(NSScreen *)toggleScreen didToggleOnEdge:(CNToggleEdge)toggleEdge
{
    CNLog(@"screen: %@ -- didToggleOnEdge: %i", toggleScreen, toggleEdge);
}

@end
