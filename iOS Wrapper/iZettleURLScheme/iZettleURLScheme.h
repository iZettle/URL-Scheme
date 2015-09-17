//
//  iZettleURLScheme.h
//  iZettle
//
//  Copyright (c) 2015 iZettle AB. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class iZettleURLSchemePaymentInfo;

typedef void(^iZettleURLSchemeOperationCompletion)(iZettleURLSchemePaymentInfo * __nullable paymentInfo,  NSError * __nullable error);

@interface iZettleURLScheme : NSObject

@property (nullable, nonatomic, copy) NSString *callbackURLScheme;
@property (nullable, nonatomic, copy) NSString *referralCode;

/*! If not nil, only an iZettle user with this account will be allowed to be logged in. */
@property (nullable, nonatomic, copy) NSString *enforcedUserAccount;

// Called when an operation has to be finished in the iZettle app before continuing.
// Defaults to display an UIAlertView with an action to return to iZettle app.
@property (nullable, nonatomic, copy) dispatch_block_t onOperationAlreadyInProgress;

@property (nonatomic, assign) BOOL verbose;


+ (iZettleURLScheme *)shared;

- (BOOL)handleOpenURL:(NSURL *)url;

@end

@interface iZettleURLScheme (Operations)

/*! Perform a payment with an amount and a reference. */
- (void)chargeAmount:(NSDecimalNumber *)amount
            currency:(nullable NSString *)currency
           reference:(nullable NSString *)reference
          completion:(iZettleURLSchemeOperationCompletion)completion;

/*! Refund a payment with a given reference. */
- (void)refundPaymentWithReference:(NSString *)originalReference
                   refundReference:(nullable NSString *)refundReference
                        completion:(iZettleURLSchemeOperationCompletion)completion;

/*! Query iZettle for payment information of a payment with a given reference. */
- (void)retrievePaymentInfoForReference:(NSString *)reference
                             completion:(iZettleURLSchemeOperationCompletion)completion;

- (void)openIZettleApp;

/*! Abort any pending operations (opertions will only be locally aborted and the iZettle app won't be notified). */
- (void)abortPendingOperations;

@end


@interface iZettleURLSchemePaymentInfo : NSObject

@property (nonatomic, readonly) NSDictionary<NSString *, id> *dictionary;   // Dictionary representation of the payment information

@property (nonatomic, readonly) NSString *referenceNumber;  // iZettles reference to the payment
@property (nonatomic, readonly) NSString *entryMode;        // EMV, MAGSTRIPE, MANUAL_ENTRY
@property (nonatomic, readonly) NSString *authorizationCode;

@property (nonatomic, readonly) NSString *obfuscatedPan;    // **** **** **** 1111
@property (nonatomic, readonly) NSString *panHash;          // Hash sum of the plain pan
@property (nonatomic, readonly) NSString *cardBrand;

@property (nonatomic, readonly, nullable) NSString *AID;
@property (nonatomic, readonly, nullable) NSString *TSI;
@property (nonatomic, readonly, nullable) NSString *TVR;
@property (nonatomic, readonly, nullable) NSString *applicationName;

// Only used for certain markets
@property (nonatomic, readonly, nullable) NSNumber *numberOfInstallments;
@property (nonatomic, readonly, nullable) NSDecimalNumber *installmentAmount;

@end

NS_ASSUME_NONNULL_END
