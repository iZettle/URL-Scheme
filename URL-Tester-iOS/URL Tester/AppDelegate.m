//
//  AppDelegate.m
//  Custom URL Launcher
//
//  Copyright (c) 2012 iZettle AB. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	ViewController *vc = (ViewController *)_window.rootViewController;
	vc.launchURLLabel.text = [url description];
	vc.returnURLTitleLabel.hidden = NO;    
	return YES;
}

@end
