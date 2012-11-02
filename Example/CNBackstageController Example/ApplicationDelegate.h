//
//  ApplicationDelegate.h
//  CNBackstageController Example
//
//  Created by cocoa:naut on 01.11.12.
//  Copyright (c) 2012 cocoa:naut. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class CNBackstageController;

@interface ApplicationDelegate : NSObject <NSApplicationDelegate>
@property (assign) NSView *applicationView;
@property (strong) CNBackstageController *backstageController;
@end
