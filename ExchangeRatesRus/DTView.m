//
//  DTView.m
//  ExRatesRus
//
//  Created by Alexey Tischenko on 29.07.15.
//  Copyright (c) 2015 Alexey Tishchenko. All rights reserved.
//

#import "DTView.h"

@implementation DTView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code

    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:12.0];
    [roundedRect addClip];
    [[UIColor colorWithRed:(126/255.0) green:(211/255.0) blue:(33/255.0) alpha:1] setFill];
    UIRectFill(self.bounds);
    
}


@end
