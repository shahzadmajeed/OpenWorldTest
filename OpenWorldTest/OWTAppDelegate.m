//
//  SKRAppDelegate.m
//  OpenWorldTest
//
//  Created by Steven Troughton-Smith on 23/12/2012.
//  Copyright (c) 2012 High Caffeine Content. All rights reserved.
//

/*
 
	The following GL code was written by Thomas Goossens, one of the
	engineers behind SceneKit @ Apple. Thanks Thomas!
 
 */

#import "OWTAppDelegate.h"
#import "SKRAppDelegate.h"

@implementation OWTAppDelegate
{
	IBOutlet NSView *_view;    
    SKRAppDelegate *_skrAppDelegate;
}

-	 (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    _skrAppDelegate = [[SKRAppDelegate alloc] initWithWindow:_window skrView:(SKRView *)_view];
}

- (void)applicationWillBecomeActive:(NSNotification *)notification
{
    [_skrAppDelegate applicationWillBecomeActive:notification];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [_skrAppDelegate applicationWillResignActive:notification];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [_skrAppDelegate applicationWillTerminate:notification];
}

@end