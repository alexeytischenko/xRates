//
//  ParseOperation.m
//  ExRatesRus
//
//  Created by Алексей on 10.01.15.
//  Copyright (c) 2015 Alexey Tishchenko. All rights reserved.
//

#import "ParseOperation.h"
#import "BankRate.h"
#import "UserPrefs.h"

NSString *kAddRatesNotificationName = @"AddRatesNotif";
NSString *kRateResultsKey = @"RateResultsKey";
NSString *kCBRFKeyRT = @"CBRFResultsKeyRT";
NSString *kCBRFKeyDT = @"CBRFResultsKeyDT";

NSString *kParseFinished = @"ParseFinished";
NSString *kParseFinishedKey = @"ParseFinishedKey";

NSString *kRatesErrorNotificationName = @"RateErrorNotif";
NSString *kRatesMessageErrorKey = @"RatesMsgErrorKey";


@interface ParseOperation () <NSXMLParserDelegate>

    @property (nonatomic) BankRate *currentRateObject;
    @property (nonatomic) NSMutableArray *currentParseBatch;
    @property (nonatomic) NSMutableString *currentParsedCharacterData;
    @property (nonatomic) NSMutableDictionary *actualBankRates;

    @property (nonatomic) NSString *cbrfRate_rate;
    @property (nonatomic) NSDate *cbrfRate_date;

@end


@implementation ParseOperation


{
    NSDateFormatter *_dateFormatter;

    BOOL _accumulatingParsedCharacterData;
    BOOL _didAbortParsing;
    NSUInteger _parsedRatesCounter;
}

- (id)initWithData:(NSData *)parseData {

    self = [super init];
    
    if (self) {
        _rateData = [parseData copy];
        
        _dateFormatter = [[NSDateFormatter alloc] init];

       // [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]]; //localTimeZone
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        _currentParseBatch = [[NSMutableArray alloc] init];
        _currentParsedCharacterData = [[NSMutableString alloc] init];
        _actualBankRates = [[NSMutableDictionary alloc] init];
        
    }
    
    return self;
}


- (void)addRatesToList:(NSArray *)exrates {
    
    assert([NSThread isMainThread]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddRatesNotificationName object:self userInfo:@{kRateResultsKey: exrates, kCBRFKeyRT: self.cbrfRate_rate, kCBRFKeyDT: self.cbrfRate_date}];
}

// The main function for this NSOperation, to start the parsing.
- (void)main {
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.rateData];
    [parser setDelegate:self];
    [parser parse];
    
    /*
     Depending on the total number of recordes parsed, the last batch might not have been a "full" batch, and thus not been part of the regular batch transfer. So, we check the count of the array and, if necessary, send it to the main thread.
     */
    if ([self.currentParseBatch count] > 0) {
        [self performSelectorOnMainThread:@selector(addRatesToList:) withObject:self.currentParseBatch waitUntilDone:YES];
    }

}

#pragma mark - Parser constants

/* Limit the number of parsed records to 200  */
static const NSUInteger kMaximumNumberOfRatesToParse = 200;

/*
 When an ExRate object has been fully constructed, it must be passed to the main thread and the table view in RootViewController must be reloaded to display it. It is not efficient to do this for every  object - the overhead in communicating between the threads and reloading the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the constant below. The optimal batch size will vary depending on the amount of data in the object and other factors, as appropriate.
 */
static NSUInteger const kSizeOfRateBatch = 5;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kEntryElementName = @"entry";
static NSString * const kLinkElementName = @"link";
static NSString * const kMapElementName = @"map";
static NSString * const kTitleElementName = @"bank";
static NSString * const kNotesName = @"notes";
static NSString * const kUpdatedElementName = @"updated";
static NSString * const kbank_idElementName = @"bank_id";
static NSString * const krate_idElementName = @"id";
static NSString * const kusdElementName = @"usd";
static NSString * const keurElementName = @"eur";
static NSString * const kFeedElementName = @"feed";
static NSString * const kcbrfRateElementName = @"cbrate";
static NSString * const kcbrfDateElementName = @"cbdate";


#pragma mark - NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    /*
     If the number of parsed rates is greater than kMaximumNumberOfRatesToParse, abort the parse.
     */
    if (_parsedRatesCounter >= kMaximumNumberOfRatesToParse) {
        /*
         Use the flag didAbortParsing to distinguish between this deliberate stop and other parser errors.
         */
        NSLog(@"End Parsing (more than MaximumNumberOfRatesToParse)");
        [[NSNotificationCenter defaultCenter] postNotificationName:kParseFinished object:self userInfo:@{kParseFinishedKey: @"more than MaximumNumberOfRatesToParse"}];
        
        _didAbortParsing = YES;
        [parser abortParsing];
    }
    if ([elementName isEqualToString:kEntryElementName]) {
        BankRate *rate = [[BankRate alloc] init];
        self.currentRateObject = rate;
    }
    else if ([elementName isEqualToString:kLinkElementName]) {
        NSString *relAttribute = [attributeDict valueForKey:@"rel"];
        if ([relAttribute isEqualToString:@"alternate"]) {
            NSString *banklink = [attributeDict valueForKey:@"href"];
            self.currentRateObject.bankURL = [NSURL URLWithString:banklink];
        }
    }
    else if ([elementName isEqualToString:kbank_idElementName] || [elementName isEqualToString:kTitleElementName] || [elementName isEqualToString:kUpdatedElementName] || [elementName isEqualToString:kNotesName] || [elementName isEqualToString:keurElementName] || [elementName isEqualToString:kusdElementName] || [elementName isEqualToString:kMapElementName] || [elementName isEqualToString:krate_idElementName] || [elementName isEqualToString:kcbrfRateElementName] || [elementName isEqualToString:kcbrfDateElementName]) {
        // For the 'title', 'updated', etc elements begin accumulating parsed character data.
        // The contents are collected in parser:foundCharacters:.
        _accumulatingParsedCharacterData = YES;
        // The mutable string needs to be reset to empty.
        [self.currentParsedCharacterData setString:@""];
    }
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if ([elementName isEqualToString:kEntryElementName]) {
        
        //если в настройках нет этого банка - добавляем в свойство ParseOperation и в настройки
        UserPrefs *userPreferences = [[UserPrefs alloc] initWithPrefs];
        
        NSString *key_string = [NSString stringWithFormat:@"%d@", self.currentRateObject.bank_id];
        if ([userPreferences.prefsDictionary[@"BANKS"] valueForKey:key_string] == nil) {
            [userPreferences savePrefswithBankKey:key_string andValue:@"1" andBankName: self.currentRateObject.bank];
        }
        else if ([[userPreferences.prefsDictionary[@"BANKS"] valueForKey:key_string] isEqual:@"1"]) {
            //если банк разрешен к показу в ленте
            
            //если switch в положении АКТУАЛЬНЫЕ, пропускаем новые актуальные рейтинги только
            if([[userPreferences.prefsDictionary valueForKey: @"SWITCH"] integerValue] == 0 || [self.actualBankRates valueForKey:key_string] == nil) {
                
                //добавили банк в актуальные рейтинги
                if ([[userPreferences.prefsDictionary valueForKey: @"SWITCH"] integerValue] == 1)   [self.actualBankRates setValue:@"1" forKey:key_string];
                
                [self.currentParseBatch addObject:self.currentRateObject];
                _parsedRatesCounter++;
                if ([self.currentParseBatch count] >= kSizeOfRateBatch) {
                    [self performSelectorOnMainThread:@selector(addRatesToList:) withObject:self.currentParseBatch waitUntilDone:YES];
                    self.currentParseBatch = [NSMutableArray array];
                }
            }
        }
    }
    else if ([elementName isEqualToString:kbank_idElementName]) {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        NSString *bid;
        if ([scanner scanUpToCharactersFromSet:
             [NSCharacterSet punctuationCharacterSet] intoString:&bid]) {
            self.currentRateObject.bank_id = [bid intValue];
        }
    }
    
    else if ([elementName isEqualToString:kTitleElementName]) {

        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        NSString *bank;
        if ([scanner scanUpToCharactersFromSet:
             [NSCharacterSet punctuationCharacterSet] intoString:&bank]) {
            self.currentRateObject.bank = bank;
        }

    }
    else if ([elementName isEqualToString:kcbrfRateElementName]) {
        
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        NSString *cbrfRate;
        if ([scanner scanUpToCharactersFromSet:
             [NSCharacterSet newlineCharacterSet] intoString:&cbrfRate]) {
            //self.cbrfRate[@"rate"] = cbrfRate;
            self.cbrfRate_rate = cbrfRate;
        }
    }
    else if ([elementName isEqualToString:kcbrfDateElementName]) {
            NSDate *ddt = [_dateFormatter dateFromString:self.currentParsedCharacterData];
            self.cbrfRate_date = ddt;
    }
    else if ([elementName isEqualToString:krate_idElementName]) {
        if (self.currentRateObject != nil) {
            NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
            NSString *rate_id;
            if ([scanner scanUpToCharactersFromSet:
                 [NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&rate_id]) {
                self.currentRateObject.rate_id = rate_id;
            }

        }
        else {
            // krate_idElementName can be found outside an entry element (i.e. in the XML header)
            // so don't process it here.
        }
      
        
    }
    else if ([elementName isEqualToString:kMapElementName]) {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        NSString *map;
        if ([scanner scanUpToCharactersFromSet:
             [NSCharacterSet  whitespaceAndNewlineCharacterSet] intoString:&map]) {
            self.currentRateObject.map = [NSURL URLWithString:map];
        }
    }
    else if ([elementName isEqualToString:kUpdatedElementName]) {
        if (self.currentRateObject != nil) {
            NSDate *ddt = [_dateFormatter dateFromString:self.currentParsedCharacterData];
            self.currentRateObject.date = ddt;
            
//            NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
//            NSString *tmpd;
//            if ([scanner scanUpToCharactersFromSet:
//                 [NSCharacterSet punctuationCharacterSet] intoString:&tmpd]) {
//                self.currentRateObject.dt = tmpd;
//            }
            
        }
        else {
            // kUpdatedElementName can be found outside an entry element (i.e. in the XML header)
            // so don't process it here.
        }
    }
    else if ([elementName isEqualToString:kNotesName]) {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        NSString *bn;
        if ([scanner scanUpToCharactersFromSet:
             [NSCharacterSet punctuationCharacterSet] intoString:&bn]) {
            self.currentRateObject.bank_note = [bn intValue];
            
        }
    }
    else if ([elementName isEqualToString:keurElementName]) {

        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        double buy, sell;
        if ([scanner scanDouble:&buy]) {
            if ([scanner scanDouble:&sell]) {
                self.currentRateObject.euro_buy = buy;
                self.currentRateObject.euro_sell = sell;
            }
        }
    }
    else if ([elementName isEqualToString:kusdElementName]) {

        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        double buy, sell;
        if ([scanner scanDouble:&buy]) {
            if ([scanner scanDouble:&sell]) {
                self.currentRateObject.usd_buy = buy;
                self.currentRateObject.usd_sell = sell;
            }
        }
    }
    else if ([elementName isEqualToString:kFeedElementName]){
        
        NSLog(@"End XML Document");
        [[NSNotificationCenter defaultCenter] postNotificationName:kParseFinished object:self userInfo:@{kParseFinishedKey: @"End XML Document"}];
        
    }
    // Stop accumulating parsed character data. We won't start again until specific elements begin.
    _accumulatingParsedCharacterData = NO;
    [self.currentParsedCharacterData setString:@""];
}

/**
 This method is called by the parser when it find parsed character data ("PCDATA") in an element. The parser is not guaranteed to deliver all of the parsed character data for an element in a single invocation, so it is necessary to accumulate character data until the end of the element is reached.
 */
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if (_accumulatingParsedCharacterData) {
        // If the current element is one whose content we care about, append 'string'
        // to the property that holds the content of the current element.
        //
        [self.currentParsedCharacterData appendString:string];
    }
}

/**
 An error occurred while parsing the data: post the error as an NSNotification to our app delegate.
 */
- (void)handleRatesError:(NSError *)parseError {
    
    assert([NSThread isMainThread]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kRatesErrorNotificationName object:self userInfo:@{kRatesMessageErrorKey: parseError}];
}

/**
 An error occurred while parsing the data, pass the error to the main thread for handling.
 (Note: don't report an error if we aborted the parse due to a max limit of records.)
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    if ([parseError code] != NSXMLParserDelegateAbortedParseError && !_didAbortParsing) {
        [self performSelectorOnMainThread:@selector(handleRatesError:) withObject:parseError waitUntilDone:NO];
    }
}


@end


