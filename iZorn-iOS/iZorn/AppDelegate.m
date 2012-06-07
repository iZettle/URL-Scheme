//
//  AppDelegate.m
//  iZorn
//
//  Copyright (c) 2012 iZettle AB. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

@synthesize window = _window;
			
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [(ViewController *)application.keyWindow.rootViewController handleURL:url];
}

@end
