//
//  AppDelegate.m
//  iZettle Wrapper Sample
//
//  Copyright (c) 2015 iZettle. All rights reserved.
//

#import "AppDelegate.h"
#import "iZettleURLScheme.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[iZettleURLScheme shared] handleOpenURL:url];
}

@end
