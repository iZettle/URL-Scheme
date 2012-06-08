#iZettle Custom URL Scheme Example Apps

The iZettle Custom URL Scheme allows your iOS app to accept card payments. These two example apps explain how to develop support for card payments in your own app. Before your app can process any payments through iZettle you need to [apply for a developer key](http://developer.izettle.com/).

##iZorn

Draw a painting on your iPhone or iPad and sell it using iZettle.

##URL Tester

An app containing only the absolute basic functionality to initiate a purchase through the iZettle app.

##Documentation

A payment is initiated from the app by opening the base URL with the `openURL:` method in `UIApplication`. The iZettle app will initiate a payment using the data sent with the query parameters. If it succeeds it will open the x-success URL. If it fails it opens x-failure.

All parameters should be percent-encoded. If sending an image it should be Base64 encoded

###Base URL

`izettle://x-callback-url/payment/1.0`

###Mandatory Query Parameters

`x-source` - name of the app as presented when completing the purchase in the iZettle app

`x-success` - URL to be opened by iZettle after a successful purchase

`x-failure` - URL to be opened by iZettle after a failed purchase

`api-key` - API-key of the calling app, this must be the key received from iZettle when registering the bundle id of the app

`price` - the amount to be charged

`curency` - currency to be used, if this does not match the currency currently used by iZettle the x-failure URL will be called with the error code `InvalidCurrency``

`title` - title for the purchase, will be displayed in the iZettle app and in the purchase history of the seller as well as on the receipt sent to the buyer

###Optional Query Parameters

`reference` - a reference string that will be saved with the purchase, if used it will be added to the x-success and x-failure URLs by the iZettle app

`image` - a Base64 encoded png or jpeg image

###Error Codes

`TechnicalError` - an error occured while processing the payment

`CancelledByUser` - the user cancelled the purchase

`InvalidCurrency` - the currency of the calling app does not match the currency in the iZettle app

`InvalidState` - the iZettle app is in an invalid state, e.g. the user is not logged in. When receiving this error you should tell the user to visit the iZettle app to verify that it's ready to receive purchases

`MissingParameter` - one or more query paramters is missing or has no value

##References

[http://izettle.com/](http://izettle.com/ "iZettle")  
[http://developer.izettle.com/](http://developer.izettle.com/ "iZettle")  
[Apple iOS Documentation - Implementing Custom URL Schemes](http://developer.apple.com/library/ios/#DOCUMENTATION/iPhone/Conceptual/iPhoneOSProgrammingGuide/AdvancedAppTricks/AdvancedAppTricks.html#//apple_ref/doc/uid/TP40007072-CH7-SW50)  
[http://x-callback-url.com/](http://x-callback-url.com/ "x-callback-url.com")
