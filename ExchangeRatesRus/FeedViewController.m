//
//  FeedViewController.m
//  ExchangeRatesRus
//
//  Created by Алексей on 08.01.15.
//  Copyright (c) 2015 Alexey Tishchenko. All rights reserved.
//

#import "FeedViewController.h"
#import "ParseOperation.h"
#import "BankRate.h"
#import "RatesTableViewCell.h"
#import "UserPrefs.h"
//#import "CJAMacros.h"

// this framework is imported so we can use the kCFURLErrorNotConnectedToInternet error code
#import <CFNetwork/CFNetwork.h>

@interface FeedViewController ()
@property (weak, nonatomic) IBOutlet UILabel *cbrf_rate;
@property (weak, nonatomic) IBOutlet UILabel *cbrf_date;
@property (weak, nonatomic) IBOutlet UIView *cbrf_view;


@property (strong, nonatomic) UserPrefs *userPreferences;
@property (nonatomic) NSMutableArray *rateList;

// queue that manages our NSOperation for parsing rate data
@property (nonatomic) NSOperationQueue *parseQueue;
@property (nonatomic, readonly) NSDateFormatter *dateFormatter;

@end

@implementation FeedViewController

- (NSDateFormatter *)dateFormatter {
    
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];//timeZoneForSecondsFromGMT:0
        NSString *localFormatDate = [NSDateFormatter dateFormatFromTemplate:@"MMM dd YYYY" options:0 locale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:localFormatDate];
        //[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        //[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return dateFormatter;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    //цвет фона
    self.view.backgroundColor = [UIColor colorWithRed:(239/255.0) green:(239/255.0) blue:(239/255.0) alpha:1];
    //цвет сепаратора
    [self.tableView setSeparatorColor:[UIColor whiteColor]];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor colorWithRed:(126/255.0) green:(211/255.0) blue:(33/255.0) alpha:1];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(loadRates)
                  forControlEvents:UIControlEventValueChanged];
    
    
    self.parseQueue = [NSOperationQueue new];
    self.rateList = [NSMutableArray array];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addRates:)
                                                 name:kAddRatesNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ratesError:)
                                                 name:kRatesErrorNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopSpin:)
                                                 name:kParseFinished object:nil];

    // if the locale changes behind our back, we need to be notified so we can update the date
    // format in the table view cells
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(localeChanged:)
                                                 name:NSCurrentLocaleDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(appEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    
    [self loadRates];
    
}

-(void) loadRates {
    
    
    [self.rateList removeAllObjects];
    [self.tableView reloadData];
    
    
    NSLog(@"self.rateList count: %lu", (unsigned long)[self.rateList count]);
    
    static NSString *feedURLString = @"http://xrates.anakiapps.com/3days-rub-usd_eur.xml";
    NSURLRequest *rateURLRequest =
    [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString]];
    
    // send the async request (note that the completion block will be called on the main thread)
    [NSURLConnection sendAsynchronousRequest:rateURLRequest
     // the NSOperationQueue upon which the handler block will be dispatched:
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               
                               // back on the main thread, check for errors, if no errors start the parsing
                               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                               
                               // here we check for any returned NSError from the server, "and" we also check for any http response errors
                               if (error != nil) {
                                   [self handleError:error];
                               }
                               else {
                                   // check for any response errors
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   //httpResponse.allHeaderFields to
                                   if ((([httpResponse statusCode]/100) == 2) && [[response MIMEType] isEqual:@"application/atom+xml"]) {
                                       
                                       // Update the UI and start parsing the data,
                                       // Spawn an NSOperation to parse the data so that the UI is not
                                       // blocked while the application parses the XML data.
                                       //
                                       ParseOperation *parseOperation = [[ParseOperation alloc] initWithData:data];
                                       [self.parseQueue addOperation:parseOperation];
                                   }
                                   else {
                                       NSString *errorString =
                                       NSLocalizedString(@"HTTP Error", @"Error message displayed when receving a connection error.");
                                       NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
                                       NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                                                  code:[httpResponse statusCode]
                                                                              userInfo:userInfo];
                                       [self handleError:reportError];
                                   }
                               }
                           }];
    
    // Start the status bar network activity indicator.
    // We'll turn it off when the connection finishes or experiences an error.
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
}

/**
 Handle errors in the download by showing an alert to the user. This is a very simple way of handling the error, partly because this application does not have any offline functionality for the user. Most real applications should handle the error in a less obtrusive way and provide offline functionality to the user.
 */
- (void)handleError:(NSError *)error {
    
   
    NSString *errorMessage = [error localizedDescription];
    NSString *alertTitle = NSLocalizedString(@"Server is down. Try later", @"Title for alert displayed when download or parse error occurs.");
    NSString *okTitle = NSLocalizedString(@"OK", @"OK Title for alert displayed when download or parse error occurs.");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle message:errorMessage delegate:nil cancelButtonTitle:okTitle otherButtonTitles:nil];
    [alertView show];

    //убираем рефреш контрол
    if ([self.refreshControl isRefreshing]) [self.refreshControl endRefreshing];

}

/**
 Our NSNotification callback from the running NSOperation to add the rate
 */
- (void)addRates:(NSNotification *)notif {
    
    assert([NSThread isMainThread]);
    [self addRatesToList:[[notif userInfo] valueForKey:kRateResultsKey] andCBRFRateRT:[[notif userInfo] valueForKey:kCBRFKeyRT] andCBRFRateDT:[[notif userInfo] valueForKey:kCBRFKeyDT]];
}

/*stop spinner*/
-(void)stopSpin:(NSNotification *)notif {
    NSLog(@"stopSpin");
    
    if ([self.refreshControl isRefreshing]) {
        dispatch_sync(dispatch_get_main_queue(), ^{     //добавил после постоянно появляющейся ошибки: message sent to deallocated instance
            [self.refreshControl endRefreshing];
            NSLog(@"stopSpin2");
        });
    }
}


/**
 Our NSNotification callback from the running NSOperation when a parsing error has occurred
 */
- (void)ratesError:(NSNotification *)notif {
    
    assert([NSThread isMainThread]);
    [self handleError:[[notif userInfo] valueForKey:kRatesMessageErrorKey]];
}


/**
 The NSOperation "ParseOperation" calls addRatesToList: via NSNotification, on the main thread which in turn calls this method, with batches of parsed objects. The batch size is set via the kSizeOfRateBatch constant.
 */
- (void)addRatesToList:(NSArray *)rates andCBRFRateRT:(NSString *) cbrfRate andCBRFRateDT: (NSDate *) cbrfDate {
    
    self.cbrf_rate.text = [[cbrfRate stringByReplacingOccurrencesOfString:@"USD" withString:@"$"] stringByReplacingOccurrencesOfString:@"EUR" withString:@"€"];
    self.cbrf_date.text = [NSString stringWithFormat:@"%@", [self.dateFormatter stringFromDate: cbrfDate]];
    //string1 = [[string1 stringByReplacingOccurrencesOfString:@"aaa" withString:@""] mutableCopy];
    
    NSInteger startingRow = [self.rateList count];
    NSInteger rateCount = [rates count];
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:rateCount];
    
    for (NSInteger row = startingRow; row < (startingRow + rateCount); row++) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [indexPaths addObject:indexPath];
    }
    
    [self.rateList addObjectsFromArray:rates];
    
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
}


#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    return @"HHHH";
//}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSLog(@"viewForHeaderInSection CALLEd");
    return self.cbrf_view;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSLog(@"heightForHeaderInSection CALLEd");
    self.userPreferences = [[UserPrefs alloc] initWithPrefs];
    NSLog(@"cbrf_view: %@", [self.userPreferences.prefsDictionary[@"CBRF"] isEqual:@"1"] ? @"YES" : @"NO");

    if([self.userPreferences.prefsDictionary[@"CBRF"] isEqual:@"1"])
        return 44.0;

    return 0.0;
}


// The number of rows is equal to the number of rates in the array.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.rateList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *kRateCellID = @"RateCellID";
    RatesTableViewCell *cell = (RatesTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kRateCellID];
    
    // Get the specific rate for this row.
    BankRate *exrate = (self.rateList)[indexPath.row];
    
    [cell configureWithRate:exrate];

    return cell;
}

#pragma mark - Share methods

/**
 * When the user taps a row in the table, display the USGS web page that displays bank web-page */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
        NSString *buttonTitle = NSLocalizedString(@"Cancel", @"Cancel");
        NSString *buttonTitle1 = NSLocalizedString(@"Show bank website in Safari", @"Show bank website in Safari");
        NSString *buttonTitle2 = NSLocalizedString(@"Find your nearest branch", @"Find your nearest branch");
        NSString *buttonTitle3 = NSLocalizedString(@"Share...", @"Share the rate");
    
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:buttonTitle destructiveButtonTitle:nil
                                                  otherButtonTitles:buttonTitle1,buttonTitle2,buttonTitle3,nil];//
    
    
        [sheet showInView:self.view];
}


/**
 * Called when the user selects an option in the sheet. The sheet will automatically be dismissed.
 */
- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    BankRate *rate = (BankRate *)(self.rateList)[selectedIndexPath.row];

    NSLog(@"Button Index %ld  map %@, rate: %@", (long)buttonIndex, rate.map, rate.rate_id);
    switch (buttonIndex) {
        case 0: {
            // open bank webpage in Safari
            [[UIApplication sharedApplication] openURL:rate.bankURL];
        }
            break;
        case 1: {
            // open branches map in Safari
            [[UIApplication sharedApplication] openURL:rate.map];
            break;
        }
        case 2: {
            //поделиться
            //if (SYSTEM_VERSION_GREATER_THAN( _iOS_7_0) ){
                 [self startShare:@{
                     @"bank": rate.bank,
                     @"date": [NSString stringWithFormat:@"%@", [self.dateFormatter stringFromDate:rate.date]],
                     @"rateBuy": [NSString stringWithFormat:@"%.2f", rate.usd_buy],
                     @"rateCell": [NSString stringWithFormat:@"%.2f", rate.usd_sell],
                     @"eur_buy": [NSString stringWithFormat:@"%.2f", rate.euro_buy],
                     @"eur_sell": [NSString stringWithFormat:@"%.2f", rate.euro_sell],
                     @"note": [NSString stringWithFormat:@"%d", rate.bank_note ],
                     @"rate_id": rate.rate_id
                }];
            //}
        
        }
    }
    [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
}


/*показываем попап шеринга*/
- (void) startShare: (NSDictionary *)shareData {

    
    NSString *note_text;
    if ([[shareData valueForKey:@"note"] isEqualToString:@"1"]) {
         note_text = [NSString stringWithFormat:@"\n%@", NSLocalizedString(@"at the beginning of the day", @"")];
    }
    else if ([[shareData valueForKey:@"note"] isEqualToString:@"2"]) {
        note_text = [NSString stringWithFormat:@"\n%@", NSLocalizedString(@"additional taxes", @"")];
    }
    else note_text = @"";
    
    NSString *exportString = [NSString stringWithFormat:@"\nUSD\t%@ - %@ руб.\nEUR\t%@ - %@ руб.%@", [shareData valueForKey:@"rateBuy"], [shareData valueForKey:@"rateCell"], [shareData valueForKey:@"eur_buy"], [shareData valueForKey:@"eur_sell"], note_text];
    
    NSString *rateUrl =[NSString stringWithFormat:@"http://xrates.anakiapps.com/rate/%@/", [shareData valueForKey:@"rate_id"]];
    NSURL *anakiWebsite = [NSURL URLWithString: rateUrl];
   // UIImage *image = [UIImage imageNamed:@"icon-to-share"];
    NSString *shareTitle = [NSString stringWithFormat:@"%@, %@ %@", NSLocalizedString(@"FB export", @"Сообщение при экспорте в соцсетях"), [shareData valueForKey:@"bank"], [shareData valueForKey:@"date"]];
    
    NSArray *objectsToShare = @[shareTitle, exportString, anakiWebsite];
    
    NSLog(@"Title: %@", shareTitle);
    NSLog(@"Body: %@", exportString);
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypeAirDrop,
                                   UIActivityTypePrint,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToVimeo,
                                   UIActivityTypePostToWeibo,
                                   UIActivityTypePostToTencentWeibo];
    
    activityVC.excludedActivityTypes = excludeActivities;
    [self presentViewController:activityVC animated:YES completion:nil];

}



#pragma mark - Service

- (void)localeChanged:(NSNotification *)notif
{
    // the user changed the locale (region format) in Settings, so we are notified here to
    // update the date format in the table view cells
    //
    [self.tableView reloadData];
}


- (void)dealloc {
    
    // we are no longer interested in these notifications:
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kAddRatesNotificationName
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kRatesErrorNotificationName
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kParseFinished
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSCurrentLocaleDidChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    //при переключении на другую вкладку
    [super viewWillDisappear:animated];
    if ([self.refreshControl isRefreshing]) [self.refreshControl endRefreshing];
    NSLog(@"ViewWILLDisappear called!!!");
    
}

//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//    NSLog(@"ViewWILLAppear FVC called!!!");
//    
//}

-(void)appEnteredBackground:(NSNotification *)appEnteredBackgroundNotification {
    
    //при получении нотификейшена, что приложение уходит на беграунд
    if ([self.refreshControl isRefreshing]) [self.refreshControl endRefreshing];
    NSLog(@"appEnteredBackground called!!!");
    
}



@end
