//
//  ViewController.m
//  Custom URL Launcher
//
//  Copyright (c) 2012 iZettle AB. All rights reserved.
//

#import "ViewController.h"


@interface NSData (encoding) 
- (NSString *)base64Encoding;
@end

@implementation NSData (encoding) 

static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

- (NSString *)base64Encoding {
	if (![self length]) return @"";
    
    char *characters = malloc((([self length] + 2) / 3) * 4);
	if (!characters) return nil;
    
	NSUInteger length = 0;
	
	NSUInteger i = 0;
	while (i < [self length]) {
		char buffer[3] = {0,0,0};
		short bufferLength = 0;
		while (bufferLength < 3 && i < [self length])
			buffer[bufferLength++] = ((char *)[self bytes])[i++];
		
		//  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
		characters[length++] = encodingTable[(buffer[0] & 0xFC) >> 2];
		characters[length++] = encodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
		if (bufferLength > 1)
			characters[length++] = encodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
		else characters[length++] = '=';
		if (bufferLength > 2)
			characters[length++] = encodingTable[buffer[2] & 0x3F];
		else characters[length++] = '=';	
	}
	
	return [[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

@end

@interface NSString (encoding) 
- (NSString *)stringByAddingPercentEscapesToURLParam;
@end

@implementation NSString (encoding) 

- (NSString*)stringByAddingPercentEscapesToURLParam {
    return (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes (NULL, (__bridge CFStringRef)self, NULL, (__bridge CFStringRef)@"=&", kCFStringEncodingUTF8);
}

@end


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *URLTextField;
@property (weak, nonatomic) IBOutlet UITextField *URLSuccessTextField;
@property (weak, nonatomic) IBOutlet UITextField *URLFailureTextField;

- (IBAction)openURL:(id)sender;

@end

@implementation ViewController {

	UITextField *_currentTextField;

}

@synthesize URLTextField, launchURLLabel, returnURLTitleLabel, URLFailureTextField, URLSuccessTextField;


- (void)viewDidUnload {
    [self setURLTextField:nil];
	[self setLaunchURLLabel:nil];
	[self setURLSuccessTextField:nil];
	[self setURLFailureTextField:nil];
	[self setReturnURLTitleLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


// Call the iZettle App

- (IBAction)openURL:(id)sender {
	[_currentTextField resignFirstResponder];
	
    // Get the success and failure URL:s from the text fields
	NSString *successCallback = [self.URLSuccessTextField.text stringByAddingPercentEscapesToURLParam];
	NSString *failureCallback = [self.URLFailureTextField.text stringByAddingPercentEscapesToURLParam];
    
    // Set up an image to attach
	UIImage *image = [UIImage imageNamed:@"espresso"];
	NSData *data = UIImagePNGRepresentation(image);
    
    // Set up the full URL used to call the iZettle App
	NSString *urlString = [NSString stringWithFormat:@"%@&x-success=%@&x-failure=%@&image=%@",
                           self.URLTextField.text,
                           successCallback,
                           failureCallback,
                           [data base64Encoding]];
	
    // Debug output for the full URL
    //NSLog(@"%@", urlString);
    
	// Call the iZettle App
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}


// Text Field Handling

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	_currentTextField = textField;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
	[self openURL:nil];
    return YES;
}




@end
