# URL Scheme Objective C Wrapper

The iZettleURLScheme is a wrapper around the URL scheme that exposes a simple Objective C API, handling the URL crafting and decomposing for you.

## Getting started

### Modify your info.plist to enable URL scheme

    <key>CFBundleURLTypes</key>
    <array>
		<dict>
			<key>CFBundleURLName</key>
			<string>com.yourcompany.yourappname</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>yourappurlscheme</string>
			</array>
		</dict>
	</array>
	
Read more about enabling URL scheme in your app in Apples [Programming Guide](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html#//apple_ref/doc/uid/TP40007072-CH6-SW2).

### Whitelist iZettle URL in your info.plist (iOS9 only)
As of iOS9, apps are required to whitelist URLs queried with `canOpenURL:`. Add `izettle` to the property `LSApplicationQueriesSchemes` in your info.plist.

### Add iZettleURLScheme to your project

Drag iZettleURLScheme.h and iZettleURLScheme.m into your project in XCode.

### Implement handling of URL scheme in your AppDelegate

Import iZettleURLScheme.h to your AppDelegate

	#import "iZettleURLScheme.h"

The iZettleURLScheme will handle callbacks for you.

	- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
        return [[iZettleURLScheme shared] handleOpenURL:url];
    }
    
### Setup iZettleURLScheme

If you've only specified one URL in the array, iZettle will call that URL 
If you have more than one URL in `CFBundleURLSchemes`, you'll have to specify which one you'd like iZettle to call upon success or failure. 

	[iZettleURLScheme shared].callbackURLScheme = @"yourappurlscheme";
	

## Operation usage

**Note** All method calls should go through the singleton returned by `[iZettleURLScheme shared]`.

To initiate a payment, call:

	- (void)chargeAmount:(NSDecimalNumber *)amount
	            currency:(NSString *)currency
               reference:(NSString *)reference
              completion:(void (^)(NSDictionary *paymentInfo, NSError *error))completion;

To refund a payment, call:

	- (void)refundPaymentWithReference:(NSString *)originalReference
                       refundReference:(NSString *)refundReference
                            completion:(void (^)(NSDictionary *paymentInfo, NSError *error))completion;

To retrive payment info for previous payment, call:

	- (void)retrievePaymentInfoForReference:(NSString *)reference
                                 completion:(iZettleURLSchemeOperationCompletion)completion;

                        
For more information about the method arguments and the returned data, please see the [URL Scheme documentation](http://github.com/iZettle/URL-Scheme).