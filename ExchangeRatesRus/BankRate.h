//
//  BankRate.h
//  ExRatesRus
//
//  Created by Alexey Tischenko on 24.06.15.
//  Copyright (c) 2015 Alexey Tishchenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BankRate : NSObject

//rate id
@property (nonatomic) NSString *rate_id;
// Name of the bank
@property (nonatomic) NSString *bank;
@property (nonatomic) int bank_id;
// Date and time
@property (nonatomic) NSDate *date;
//@property (nonatomic) NSString *dt;
// bank URL
@property (nonatomic) NSURL *bankURL;
@property (nonatomic) NSURL *map;
// buy and sell exchange rates
@property (nonatomic) double usd_buy;
@property (nonatomic) double usd_sell;
@property (nonatomic) double euro_buy;
@property (nonatomic) double euro_sell;

// данные на начало дня
@property (nonatomic) int bank_note;

@end
