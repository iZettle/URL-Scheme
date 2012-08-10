//
//  UIView+ValidationError.m
//  iZorn
//
//  Created by Mattias Jähnke on 2012-08-10.
//  Copyright (c) 2012 Bit of Mind AB. All rights reserved.
//

#import "UIView+ValidationError.h"

@implementation UIView (ValidationError)

-(void)showValidationError {
    self.layer.shadowColor = [[UIColor redColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(0, 0);
    self.layer.shadowRadius = 15;
    self.layer.shadowOpacity = .0f;
    CABasicAnimation *anim2 = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    anim2.fromValue = [NSNumber numberWithFloat:1.0];
    anim2.toValue = [NSNumber numberWithFloat:0.0];
    anim2.duration = 1.0f;
    [self.layer addAnimation:anim2 forKey:@"shadowOpacity2"];
}

@end
