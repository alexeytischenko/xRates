//
//  RatesTableViewCell.h
//  ExRatesRus
//
//  Created by Алексей on 11.01.15.
//  Copyright (c) 2015 Alexey Tishchenko. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BankRate;

// NSNotification name for open TableCell sharing screen
extern NSString *kStartSharingNotificationName;

@interface RatesTableViewCell : UITableViewCell

- (void)configureWithRate:(BankRate *)rate;


@end
