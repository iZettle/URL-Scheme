//
//  ViewController.m
//  iZorn
//
//  Copyright (c) 2012 iZettle AB. All rights reserved.
//

#import "ViewController.h"
#import "NSData+Base64.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <QuartzCore/QuartzCore.h>

#define CURRENCY @"SEK"

@interface ViewController () <MFMailComposeViewControllerDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet PaintingView *paintingView;
@property (weak, nonatomic) IBOutlet UITextField *amountTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet UIView *modalView;
@property (weak, nonatomic) IBOutlet UIButton *modalCancelButton;
@property (weak, nonatomic) IBOutlet UIButton *modalSellButton;
@property (weak, nonatomic) IBOutlet UIButton *sellButton;
@property (weak, nonatomic) IBOutlet UIImageView *placeholderImage;
@property (weak, nonatomic) IBOutlet UIView *dimmerView;
@property (weak, nonatomic) IBOutlet UIView *paletteView;

@end


@implementation ViewController

@synthesize paintingView;
@synthesize amountTextField;
@synthesize descriptionTextField;
@synthesize modalView;
@synthesize modalCancelButton;
@synthesize modalSellButton;
@synthesize sellButton;
@synthesize placeholderImage;
@synthesize dimmerView;
@synthesize paletteView;


#pragma mark - Basic view handling

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup the painting view
    self.paintingView.backgroundColor = [UIColor clearColor];
    [self.paintingView setBrushColorWithRed:0 green:.2 blue:.7];
	self.paintingView.delegate = self;
    
    // Round off the corners of the modal buttons
    self.modalCancelButton.layer.cornerRadius = 5.00;
    self.modalSellButton.layer.cornerRadius = 5.00;
}

- (void)viewDidUnload
{
    [self setPaintingView:nil];
    [self setAmountTextField:nil];
    [self setDescriptionTextField:nil];
    [self setModalView:nil];
    [self setModalCancelButton:nil];
    [self setModalSellButton:nil];
    [self setSellButton:nil];
    [self setPlaceholderImage:nil];
    [self setDimmerView:nil];
    [self setPaletteView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (IBAction)whoWasZorn:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://en.wikipedia.org/wiki/Anders_Zorn"]];
}


#pragma mark - Painting and colors

- (IBAction)erasePainting:(id)sender {
    [self.paintingView erase];
    [UIView animateWithDuration:0.3 animations:^{
        self.placeholderImage.alpha = 1.0;
    }];
}

- (void)didBeginPainting {
    [UIView animateWithDuration:0.3 animations:^{
        self.placeholderImage.alpha = 0;
    }];
}

- (IBAction)changeColor:(UIButton *)sender {
    switch (sender.tag) {
        case 1:
            [self.paintingView setBrushColorWithRed:0 green:.7 blue:.2];
            break;
        case 2:
            [self.paintingView setBrushColorWithRed:.8 green:0 blue:0];
            break;
        case 3:
            [self.paintingView setBrushColorWithRed:0 green:.2 blue:0.7];
            break;
    }
}


#pragma mark - Handle the modal and form

- (IBAction)showModal:(id)sender
{
    [UIView animateWithDuration:0.3 animations:^{
        self.modalView.alpha = 1.0;
        self.dimmerView.alpha = 0.5;
    }];
}

- (IBAction)next:(id)sender
{
    [self.amountTextField becomeFirstResponder];
}

- (IBAction)closeModal:(id)sender
{
    [UIView animateWithDuration:0.3 animations:^{
        self.modalView.alpha = 0.0;
        self.dimmerView.alpha = 0.0;
    }];
    [self.amountTextField setText:@""];
    [self.descriptionTextField setText:@""];
    [self.amountTextField resignFirstResponder];
    [self.descriptionTextField resignFirstResponder];
}

- (void)adjustFormIsEditing:(BOOL)isEditing {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [UIView animateWithDuration:.29 delay:.01 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
            
            CGRect frame = self.modalView.frame;
            frame.origin.y = isEditing ? -10 : 100;
            self.modalView.frame = frame;
            
        } completion:nil];
    }     
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self adjustFormIsEditing:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self adjustFormIsEditing:NO];
}

#pragma mark - Communicate with the iZettle app

// Helper method to correctly escape the params sent to the iZettle app

- (NSString *)addPercentEscapesToURLString:(NSString*)string
{
    return (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes (NULL, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)@"=&", kCFStringEncodingUTF8);
}


// Call the iZettle app

- (IBAction)settle:(id)sender
{
    NSString *appName = @"iZorn";
    NSString *apiKey = @"demo-app-izorn";
    NSString *escapedPrice = [self.amountTextField.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *escapedDescription = [self.descriptionTextField.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if([escapedDescription length] <= 0) {
        [self.modalView showValidationError];
        return;
    }
    
    if([[[NSRegularExpression regularExpressionWithPattern:@"^\\d+$" options:0 error:nil] matchesInString:escapedPrice options:0 range:NSMakeRange(0, escapedPrice.length)] count] == 0) {
        [self.modalView showValidationError];
        return;
    }
    
   // NSString *encodedDescription = [self.paintingView.image
    
	NSString *successCallback = [self addPercentEscapesToURLString:@"izorn://success"];
	NSString *failureCallback = [self addPercentEscapesToURLString:@"izorn://failure"];
    
    UIImage *originalImage = self.paintingView.image;
    CGSize destinationSize = CGSizeMake(320, 320);
    
    UIGraphicsBeginImageContext(destinationSize);
    [originalImage drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSString *encodedImage = [UIImageJPEGRepresentation(scaledImage, .5) base64Encoding];
    
	NSString *urlString = [NSString stringWithFormat:@"izettle://x-callback-url/payment/1.0?x-source=%@&api-key=%@&price=%@&currency=%@&title=%@&x-success=%@&x-failure=%@&image=%@", appName, apiKey, escapedPrice, CURRENCY, escapedDescription, successCallback, failureCallback, encodedImage];
	
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"%@", url);
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}


// Handle the callback URL

- (BOOL)handleURL:(NSURL *)url
{
    NSLog(@"handleURL: %@", url);
    if ([[url absoluteString] hasPrefix:@"izorn://success"]) {
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        [picker setSubject:self.descriptionTextField.text];
        [picker addAttachmentData:UIImageJPEGRepresentation(self.paintingView.image, .8) mimeType:@"image/jpeg" fileName:self.descriptionTextField.text];
        [self presentModalViewController:picker animated:YES];
        return YES;
    } else if ([[url absoluteString] hasPrefix:@"izorn://failure"]) {
        self.modalView.alpha = 0.0;
        self.dimmerView.alpha = 0.0;
		[self.amountTextField resignFirstResponder];
		[self.descriptionTextField resignFirstResponder];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something went wrong" message:[url absoluteString] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		
		return YES;
	}
    return NO;
}


#pragma mark - Mail composer

// After a painting is sold, we send it to the customer

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {	
	[self dismissModalViewControllerAnimated:YES];
	[self closeModal:nil];
	[self.paintingView erase];
}


@end

