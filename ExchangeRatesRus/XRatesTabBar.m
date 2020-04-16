//
//  XRatesTabBar.m
//  ExRatesRus
//
//  Created by Alexey Tischenko on 27.07.15.
//  Copyright (c) 2015 Alexey Tishchenko. All rights reserved.
//

#import "XRatesTabBar.h"

@implementation XRatesTabBar

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


-(CGSize)sizeThatFits:(CGSize)size
{
    CGSize sizeThatFits = [super sizeThatFits:size];
    sizeThatFits.height = 60;
    
    return sizeThatFits;
}

@end
