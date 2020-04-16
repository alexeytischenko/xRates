//
//  ParseOperation.h
//  ExRatesRus
//
//  Created by Алексей on 10.01.15.
//  Copyright (c) 2015 Alexey Tishchenko. All rights reserved.
//

#import <Foundation/Foundation.h>

// NSNotification name for sending rate data back to the app delegate
extern NSString *kAddRatesNotificationName;
// NSNotification userInfo key for obtaining the rate data
extern NSString *kRateResultsKey;
extern NSString *kCBRFKeyRT;
extern NSString *kCBRFKeyDT;

// NSNotification name for reporting errors
extern NSString *kRatesErrorNotificationName;
// NSNotification userInfo key for obtaining the error message
extern NSString *kRatesMessageErrorKey;

//Notification Parse operation Compleat
extern NSString *kParseFinished;
// NSNotification userInfo key for obtaining parseFinish flag
extern NSString *kParseFinishedKey;


@interface ParseOperation : NSOperation

@property (copy, readonly) NSData *rateData;

- (id)initWithData:(NSData *)parseData;

@end
