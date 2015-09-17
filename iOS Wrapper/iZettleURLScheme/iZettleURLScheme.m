//
//  iZettleURLScheme.m
//  iZettle
//
//  Copyright (c) 2015 iZettle AB. All rights reserved.
//

#import "iZettleURLScheme.h"
#import <UIKit/UIKit.h>

@interface iZettleURLSchemePaymentInfo ()
- (id)initWithDictionary:(NSDictionary *)dictionary;
@end

@interface NSMutableDictionary(AddIfNotNull)
- (void)setValueIfNotNullOrEmpty:(id)value forKey:(NSString *)key;
@end

@interface NSError (IZErrorSerialization)
+ (NSError *)iZettleErrorFromStringRepresentation:(NSString *)string;
@end

@interface NSString (URLParams)
- (NSString *)stringByAppendingURLParams:(NSDictionary *)params;
- (NSDictionary *)parseURLParams;
@end

@interface iZettleURLScheme () <UIAlertViewDelegate>

@property (nonatomic, readonly) NSMutableDictionary *pendingCompletions;

@end

static NSString * const kXCUHost          = @"callback-url";
static NSString * const kXCUErrorMessage  = @"errorMessage";

@implementation iZettleURLScheme

+ (iZettleURLScheme *)shared {
    static iZettleURLScheme* shared = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shared = [[iZettleURLScheme alloc] init];
        NSArray *urlTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
        if (urlTypes.count == 1) {
            NSArray *schemes = ((NSDictionary*)urlTypes[0])[@"CFBundleURLSchemes"];
            if (schemes.count == 1) {
                shared.callbackURLScheme = schemes[0];
            }
        }
        shared.onOperationAlreadyInProgress = ^{
            if (shared.verbose) {
                NSLog(@"Will display return to iZettle alert.");
            }
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Return to iZettle"
                                                                message:@"You need to finish your current iZettle operation before continuing."
                                                               delegate:shared cancelButtonTitle:@"Cancel" otherButtonTitles:@"Return to iZettle", nil];
            alertView.tag = 2;
            [alertView show];
            
        };
        
        shared->_pendingCompletions = [NSMutableDictionary dictionary];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            if ([shared.pendingCompletions count] && shared.onOperationAlreadyInProgress) {
                shared.onOperationAlreadyInProgress();
            }
        }];
    });
    return shared;
}

- (void)callAction:(NSString *)action withParameters:(NSDictionary *)parameters completion:(iZettleURLSchemeOperationCompletion)completion {
    if (!self.callbackURLScheme) {
        @throw [NSException exceptionWithName:@"iZettleURLSchemeException" reason:@"Callback URL-Scheme not set" userInfo:nil];
    }

    if (!completion) {
        @throw [NSException exceptionWithName:@"iZettleURLSchemeException" reason:@"Completion was nil" userInfo:nil];
    }

    if (self.verbose && self.pendingCompletions.count) {
        NSLog(@"Warning: Calling opertion when there are pending operations.");
    }
    
    NSString *urlString = [NSString stringWithFormat:@"izettle://api/%@?", action];
    
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"iZettle not Installed"
                                                            message:@"You need to install the iZettle app from the App Store to be able to proceed."
                                                           delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"App Store", nil];
        alertView.tag = 1;
        [alertView show];
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"com.izettle.url-scheme30.error" code:2 userInfo:@{ NSLocalizedDescriptionKey : @"iZettle app not installed" }]);
        }
        return;
    }
    
    NSString *operationUUID = [NSUUID UUID].UUIDString;

    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    
    [mutableParameters setValueIfNotNullOrEmpty:self.referralCode forKey:@"referralCode"];
    [mutableParameters setValueIfNotNullOrEmpty:self.enforcedUserAccount forKey:@"enforcedUserAccount"];

    
    mutableParameters[@"successURL"] = [NSString stringWithFormat:@"%@://%@/success?operationUUID=%@", self.callbackURLScheme, kXCUHost, operationUUID];
    mutableParameters[@"failureURL"] = [NSString stringWithFormat:@"%@://%@/failure?operationUUID=%@", self.callbackURLScheme, kXCUHost, operationUUID];
    mutableParameters[@"urlWrapper"] = @"true";
    
    self.pendingCompletions[operationUUID] = completion;
    
    urlString = [urlString stringByAppendingURLParams:mutableParameters];
    
    if (_verbose) {
        NSLog(@"Action [%@] resolved to URL %@", action, urlString);
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        if (alertView.tag == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/apple-store/id447785763?mt=8"]];
        } else {
            [self openIZettleApp];
        }
    } else {
        [self abortPendingOperations];
    }
}

- (BOOL)handleOpenURL:(NSURL*)url {
    if (![url.scheme isEqualToString:self.callbackURLScheme]) {
        return NO;
    }
    
    if (![url.host isEqualToString:kXCUHost]) {
        return NO;
    }
    
    NSMutableDictionary *params = [[url.query parseURLParams] mutableCopy];
    
    NSString *operationUUID = params[@"operationUUID"] ?: @"";

    iZettleURLSchemeOperationCompletion completion = self.pendingCompletions[operationUUID];

    if (!completion) {
        return NO;
    }
    
    [self.pendingCompletions removeObjectForKey:operationUUID];
    
    if ([url.path isEqualToString:@"/success"]) {
        NSMutableDictionary *info = [params mutableCopy];
        [info removeObjectForKey:@"operationUUID"];
        completion([[iZettleURLSchemePaymentInfo alloc] initWithDictionary:info] , nil);
    } else {
        NSError *error = [NSError iZettleErrorFromStringRepresentation:params[kXCUErrorMessage]];
        if (!error) {
            error = [NSError errorWithDomain:@"com.izettle.url-scheme30.error"
                                        code:3
                                    userInfo:@{ NSLocalizedDescriptionKey : params[kXCUErrorMessage] ?: @"Unknown error" }];
        }
        completion(nil, error);
        
        if ([error.domain isEqualToString:@"com.izettle.session.error"] && error.code == 10 && self.onOperationAlreadyInProgress) {
            self.onOperationAlreadyInProgress();
        }
    }
    
    return YES;
}

@end

@implementation iZettleURLScheme (Operations)

- (void)chargeAmount:(NSDecimalNumber *)amount currency:(NSString *)currency reference:(NSString *)reference completion:(iZettleURLSchemeOperationCompletion)completion {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    [parameters setObject:[amount stringValue] forKey:@"amount"];
    [parameters setValueIfNotNullOrEmpty:currency forKey:@"currency"];
    [parameters setValueIfNotNullOrEmpty:reference forKey:@"reference"];
    
    [self callAction:@"payment/charge" withParameters:parameters completion:completion];
}

- (void)refundPaymentWithReference:(NSString *)originalReference refundReference:(NSString *)refundReference completion:(iZettleURLSchemeOperationCompletion)completion {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    [parameters setObject:originalReference forKey:@"originalReference"];
    [parameters setValueIfNotNullOrEmpty:refundReference forKey:@"reference"];
    
    [self callAction:@"payment/refund" withParameters:parameters completion:completion];
}

- (void)retrievePaymentInfoForReference:(NSString *)reference completion:(iZettleURLSchemeOperationCompletion)completion {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    [parameters setObject:reference forKey:@"reference"];
    
    [self callAction:@"payment/query" withParameters:parameters completion:completion];
}

- (void)openIZettleApp {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"izettle://api/open"]];
}

- (void)abortPendingOperations {
    NSArray *completions = self.pendingCompletions.allValues;
    [self.pendingCompletions removeAllObjects];
    for (iZettleURLSchemeOperationCompletion completion in completions) {
        completion(nil, [NSError errorWithDomain:@"com.izettle.url-scheme30.error" code:10 userInfo:@{ NSLocalizedDescriptionKey : @"Operation was abandoned" }]);
    }
}

@end


@implementation NSString (URLParams)

- (NSDictionary *)parseURLParams {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    
    NSArray *pairs = [self componentsSeparatedByString:@"&"];
    
    [pairs enumerateObjectsUsingBlock:^(NSString *pair, NSUInteger idx, BOOL *stop) {
        NSArray *comps = [pair componentsSeparatedByString:@"="];
        if ([comps count] == 2) {
            [result setObject:[comps[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:comps[0]];
        }
    }];
    
    return result;
}

- (NSString *)stringByAppendingURLParams:(NSDictionary *)params {
    NSMutableString *result = [NSMutableString stringWithString:self];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([result rangeOfString:@"?"].location != NSNotFound) {
            if (![result hasSuffix:@"&"] && ![result hasSuffix:@"?"]) {
                [result appendString:@"&"];
            }
        } else {
            [result appendString:@"?"];
        }
        
        NSString *escapedObj = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)[obj description], NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8));
        [result appendFormat:@"%@=%@", key, escapedObj];
    }];
    
    return result;
}

@end

@implementation NSMutableDictionary(AddIfNotNull)

- (void)setValueIfNotNullOrEmpty:(id)value forKey:(NSString *)key {
    if (!value || [value isEqual:[NSNull null]] || ([value isKindOfClass:[NSString class]] && ![value length]))
        return;
    [self setValue:value forKey:key];
}

@end

@implementation NSError (IZErrorSerialization)

+ (NSError *)iZettleErrorFromStringRepresentation:(NSString *)string {
    if (!string) return nil;
    
    NSError *regexError;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\S+)\\((-?\\d+)\\) - (?:(?:(.*) <UnderlyingError>: (.*))|((.*)))$" options:0 error:&regexError];
    NSArray *matches = [regex matchesInString:string options:0 range:(NSRange){0, string.length}];
    NSTextCheckingResult *textCheckingResult = matches.firstObject;
    if (regexError || matches.count <= 0 || textCheckingResult.numberOfRanges < 3) {
        return nil;
    }
    NSError *underlyingError;
    NSInteger messageIndex = 5;
    NSRange range = [textCheckingResult rangeAtIndex:4];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (range.location != NSNotFound) {
        underlyingError = [NSError iZettleErrorFromStringRepresentation:[string substringWithRange:range]];
        messageIndex = 3;
    }
    
    [userInfo setValueIfNotNullOrEmpty:[string substringWithRange:[textCheckingResult rangeAtIndex:messageIndex]] forKey:NSLocalizedDescriptionKey];
    [userInfo setValueIfNotNullOrEmpty:underlyingError forKey:NSUnderlyingErrorKey];
    
    return [NSError errorWithDomain:[string substringWithRange:[textCheckingResult rangeAtIndex:1]]
                               code:[[string substringWithRange:[textCheckingResult rangeAtIndex:2]] integerValue]
                           userInfo:userInfo];
}

@end


@implementation iZettleURLSchemePaymentInfo {
    NSDictionary *_dictionary;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _dictionary = [dictionary copy];
    }
    return self;
}

- (NSDictionary *)dictionary {
    return _dictionary;
}

- (NSString *)referenceNumber {
    return _dictionary[@"referenceNumber"];
}

- (NSNumber *)numberOfInstallments {
    return _dictionary[@"numberOfInstallments"];
}

- (NSDecimalNumber *)installmentAmount {
    return _dictionary[@"installmentAmount"];
}

- (NSString *)entryMode {
    return _dictionary[@"entryMode"];
}

- (NSString *)authorizationCode {
    return _dictionary[@"authorizationCode"];
}

- (NSString *)obfuscatedPan {
    return _dictionary[@"obfuscatedPan"];
}

- (NSString *)panHash {
    return _dictionary[@"panHash"];
}

- (NSString *)cardBrand {
    return _dictionary[@"cardBrand"];
}

- (NSString *)TVR {
    return _dictionary[@"TVR"];
}

- (NSString *)TSI {
    return _dictionary[@"TSI"];
}

- (NSString *)AID {
    return _dictionary[@"AID"];
}

- (NSString *)applicationName {
    return _dictionary[@"applicationName"];
}

- (NSString *)description {
    return _dictionary.description;
}

@end
