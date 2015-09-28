# iZettle URL Scheme

**Note: the iZettle URL Scheme is only avaiblable for iOS at the moment.**

iZettle allows you to take payments from your own app or website with a URL Scheme. The document below describes the protocol used to communicate with the iZettle app.

If you're developing a native iOS app, we've prepared a wrapper around the URL Scheme to make the integration as smooth as possible.

* [iOS wrapper](http://github.com/iZettle/URL-Scheme/iOS)

## Protocol introduction

You communicate with the iZettle app by composing and open URLs using iZettle's URL Scheme 'izettle'. To allow iZettle to respond back to your app, your URL must include both success and failure URL. 

	izettle://api/<operation>?successURL=[successURL]&failureURL=[failureURL]

- **operation**: See list of supported opertions below.
- **successURL**: This URL will be opened by iZettle when an operation is considered successful. iZettle  will append the operation's result as parameters to the URL.
- **failureURL**: If an operation failed or is cancelled by the user, iZettle will open this URL and append a descriptive error message in the URL parameter **errorMessage**.

**Important**: Make sure you're app is setup correctly on your specific platform in order for iZettle to be able to open up your app via a URL scheme. All URLs and parameters are case sensitive.



## Operations

All operations accept the following parameters:

- **referralCode** _(optional)_: Referral code if you have one.
- **enforcedUserAccount** _(optional)_: If set, operations will be restricted to only work for the specified iZettle username. 


### Charge Payment

Perform a payment. 

	izettle://api/payment/charge?amount=[amount]&currency=[currency]&reference=[reference]&referralCode=[referralCode]...

- **amount**: The amount to be charged. Can only contain numbers [0-9] and [.] as decimal separator e.g `1729.00`.
- **currency** _(optional)_: Only used for validation. Payments are always performed in the logged in users currency. If the value of this parameter doesn't match the users currency the user will be notified and then logged out. Currency is described using [ISO 4217](http://www.xe.com/iso4217.php), e.g. `SEK`
- **reference** _(optional)_: The payment reference. Used to identify an iZettle payment, used to perform a refund. Max length 128.

See **PaymentInfo** for information about the parameters returned upon success.

Example:
	
	izettle://api/payment/charge?amount=199.50&currency=SEK&reference=k7NK68arEeS0...

### Refund payment

Refund a payment with a given reference.

	izettle://api/payment/refund?originalReference=[originalReference]&reference=[reference]...

- **originalReference**: The reference of the payment that is to be refunded.
- **reference** _(optional)_: The reference of the refund. Max length 128.

See **PaymentInfo** for information about the parameters returns upon success.

Example:
	
	izettle://api/payment/refund?originalReference=k7NK68arEeS0&reference=7He7ab3h55...

### Query for PaymentInfo

Retrieve the state of a payment. Useful if your app is uncertain if a payment succeeded or not (e.g. after an app crash).

	izettle://api/payment/query?reference=[reference]...

- **reference**: The reference of the payment to retrive info about.

See **PaymentInfo** for information about the parameters returns upon success.

Example:
	
	izettle://api/payment/query?reference=k7NK68arEeS0...

### Open the iZettle app

Just open the iZettle app. Use this to return to the iZettle app if an operation has not been finsihed when the user manually switches back to your app.

	izettle://api/open


## Payment Info

When information about a payment is returned to the calling app, the following parameters will be appended to the URL.

- **referenceNumber** - iZettles reference to the payment (not to be confused with the reference provided by you during a charge or refund operation)
- **entryMode** - EMV, MAGSTRIPE or MANUAL_ENTRY
- **obfuscatedPan** - e.g. _"\*\*\*\* \*\*\*\* \*\*\*\* 1111"_
- **panHash** - a hash of the pan
- **cardBrand**
- **AID***
- **TSI***
- **TVR***
- **applicationName***
- **numberOfInstallments**
- **installmentAmount**

\* These fields are only for EMV (non refund) payments

### Example of a card reader chip payment:

	entryMode = EMV
	obfuscatedPan = "**** **** **** 0640"
	panHash = 0092C7D95900033B84CE08B43F7E973485FB7081
	cardBrand = MASTERCARD
    AID = A0000000041010
    TSI = 4000
    TVR = 8000000000
    applicationName = MasterCard
    
### Example of a card reader swipe payment:

    entryMode = MAGSTRIPE
    obfuscatedPan = "**** **** **** 2481"
    panHash = 99426D012C6740D9AEC8E26580E8640A196E3C27
    cardBrand = MASTERCARD

### Example of a manual entry payment:

	entryMode = MANUAL_ENTRY
    obfuscatedPan = "**** **** **** 1111"
    panHash = 3E00BFA91E68894D5B6911A93C0F8C185708877B
    cardBrand = VISA


## Errors
iZettle will display any errors that occur during an operation to the user, the error returned as a paramater in failureURL is only intended to be used by developers for debugging, diagnostics and logging to be able to better communicate errors to iZettle. You should never present the returned errors to the end user.
