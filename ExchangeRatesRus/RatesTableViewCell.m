//
//  RatesTableViewCell.m
//  ExRatesRus
//
//  Created by Алексей on 11.01.15.
//  Copyright (c) 2015 Alexey Tishchenko. All rights reserved.
//

#import "RatesTableViewCell.h"
#import "BankRate.h"

NSString *kStartSharingNotificationName = @"ShareRateKey";


@interface RatesTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *bank;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *note;
@property (weak, nonatomic) IBOutlet UILabel *eur_buy;
@property (weak, nonatomic) IBOutlet UILabel *eur_sell;
@property (weak, nonatomic) IBOutlet UILabel *rateBuy;
@property (weak, nonatomic) IBOutlet UILabel *rateCell;
//- (IBAction)shareButtonPressed:(id)sender;
//@property (weak, nonatomic) IBOutlet UIButton *shareButton;



@property (nonatomic, readonly) NSDateFormatter *dateFormatter;
@property (nonatomic, weak) NSString *rate_id;

@end

@implementation RatesTableViewCell

- (void)configureWithRate:(BankRate *)rate {

    self.bank.text = rate.bank;
    
    self.date.text = [NSString stringWithFormat:@"%@", [self.dateFormatter stringFromDate:rate.date]];
    //self.date.text = rate.dt;
    self.rateBuy.text = [NSString stringWithFormat:@"%.2f", rate.usd_buy];
    self.rateCell.text = [NSString stringWithFormat:@"%.2f", rate.usd_sell];
    self.eur_buy.text = [NSString stringWithFormat:@"%.2f", rate.euro_buy];
    self.eur_sell.text = [NSString stringWithFormat:@"%.2f", rate.euro_sell];
    
    self.note.text = @"";
    if (rate.bank_note == 1)
        self.note.text = NSLocalizedString(@"at the beginning of the day", @"курс только на начало дня");
    else if (rate.bank_note == 2)
        self.note.text = NSLocalizedString(@"additional taxes", @"дополнительные комиссии");
    
    self.rate_id = [NSString stringWithString:rate.rate_id];
    

}


- (NSDateFormatter *)dateFormatter {
    
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];//timeZoneForSecondsFromGMT:0
        NSString *localFormatDate = [NSDateFormatter dateFormatFromTemplate:@"MMM dd, HH:mm" options:0 locale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:localFormatDate];
        //[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        //[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return dateFormatter;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}



@end
