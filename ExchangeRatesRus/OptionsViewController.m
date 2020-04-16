//
//  OptionsViewController.m
//  ExRatesRus
//
//  Created by Алексей on 11.01.15.
//  Copyright (c) 2015 Alexey Tishchenko. All rights reserved.
//

#import "OptionsViewController.h"
#import "UserPrefs.h"
//#import "CJAMacros.h"

@interface OptionsViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *actualControl;
@property (weak, nonatomic) IBOutlet UISwitch *usdControl;
@property (weak, nonatomic) IBOutlet UISwitch *eurControl;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollview;
@property (weak, nonatomic) IBOutlet UIView *contentview;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentHeight;

@property (strong, nonatomic) UIColor *titlecolor;
@property (strong, nonatomic) UIColor *titlecolorDis;

- (IBAction)eurSwitch:(id)sender;
- (IBAction)usdSwitch:(id)sender;
- (IBAction)actualSwitch:(id)sender;


@property (strong, nonatomic) UserPrefs *userPreferences;
@end

@implementation OptionsViewController



//- (void)viewDidLoad {
//    [super viewDidLoad];
//    [self buildList];
//    NSLog(@"ViewDIDLoad Called!!!!");
//    
//}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //перестраиваем список: очищаем view, добавляем контролы заново
    //Список перестраивается каждый раз заново, чтобы можно было безболезненно (без перезапуска клиентских аппликейшз) добавлять новые банки на сервере
    [self buildList];
//    if (SYSTEM_VERSION_GREATER_THAN( _iOS_7_0) )
//    else {
//        //для IOS6
//        self.userPreferences = [[UserPrefs alloc] initWithPrefs];
//        if (self.userPreferences.prefsDictionary[@"SWITCH"] != nil && [self.userPreferences.prefsDictionary[@"SWITCH"] integerValue] == 1) {
//            self.actualControl.selectedSegmentIndex = 1;
//        } else self.actualControl.selectedSegmentIndex = 0;
//        
//    }
    
        
    NSLog(@"OPTIONS_VIEWCONTROLLER: viewWillAppear Called!!!!");
}



-(void)  buildList {
    
    //    for (int i = 0 ; i < [self.contentview.subviews count] ; i++)
    //    {
    //        [self.contentview removeConstraints:[[self.contentview.subviews objectAtIndex: i] constraints]];
    //    }
    //[self.scrollview removeConstraints:[self.contentview constraints]];
    [[self.contentview subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    
    self.titlecolor = [UIColor colorWithRed:(104/255.0) green:(104/255.0) blue:(113/255.0) alpha:1];
    self.titlecolorDis = [UIColor colorWithRed:(201/255.0) green:(201/255.0) blue:(201/255.0) alpha:1];
    UIFont *titleFont = [UIFont systemFontOfSize:19.0];
    
    //получаем ссылку на основную Queue и содздаем еще одну
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    NSOperationQueue *myQueue = [[NSOperationQueue alloc] init];
    
    //операция чтения настроек
    NSBlockOperation *readPrefsOperation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakreadPrefsOperation = readPrefsOperation;
    [weakreadPrefsOperation addExecutionBlock:^{
        self.userPreferences = [[UserPrefs alloc] initWithPrefs];
    }];
    
    //операция отображения контролов
    NSBlockOperation *showOperation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakshowOperation = showOperation;
    [weakshowOperation addExecutionBlock:^{
        
        if (self.userPreferences.prefsDictionary[@"SWITCH"] != nil && [self.userPreferences.prefsDictionary[@"SWITCH"] integerValue] == 1) {
            self.actualControl.selectedSegmentIndex = 1;
        } else self.actualControl.selectedSegmentIndex = 0;
        

        //добавляем ЦБ РФ
        UILabel *cbrfLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 50)];
        cbrfLabel.text = NSLocalizedString(@"The Central Bank of the RF", @"Центральный банк РФ");
        [cbrfLabel setFont:titleFont];
        [cbrfLabel setTextColor:[self.userPreferences.prefsDictionary[@"CBRF"] isEqual:@"1"] ? self.titlecolor : self.titlecolorDis];
        cbrfLabel.tag = 0;
        [self.contentview addSubview:cbrfLabel];
        //переключатель
        UISwitch *cbrfSwitch = [[UISwitch alloc] init];// initWithFrame:CGRectMake(0, 75 + i*50, 0, 0)];
        cbrfSwitch.translatesAutoresizingMaskIntoConstraints = NO;  //This part hung me up --- doesn't work without it!!!!!!!!!!!!!!!!!!!
        
        [cbrfSwitch addTarget:self action:@selector(changeCBRFSwitch:) forControlEvents:UIControlEventValueChanged];
        cbrfSwitch.tag = 0;
        [cbrfSwitch setOnTintColor:[UIColor colorWithRed:(126/255.0) green:(211/255.0) blue:(33/255.0) alpha:1]];
        [self.contentview addSubview:cbrfSwitch];
        NSLayoutConstraint *leadingConstraint= [NSLayoutConstraint constraintWithItem:cbrfSwitch attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:cbrfSwitch.superview attribute:NSLayoutAttributeRight multiplier:1.0 constant:-2];
        NSLayoutConstraint *topConstraint= [NSLayoutConstraint constraintWithItem:cbrfSwitch attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cbrfSwitch.superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:5];
        
        [self.contentview addConstraints:@[leadingConstraint,topConstraint]];
        //состояние переключателя
        [cbrfSwitch setOn: [self.userPreferences.prefsDictionary[@"CBRF"] isEqual:@"1"] ? YES : NO];
        
        ////ЦБ РФ конец
        
        CGFloat scrollHeight = 50.0;
        
        if (self.userPreferences.prefsDictionary[@"BANKS"] != nil) {
            //NSLog(@"Iterate prefs:%@",self.userPreferences.prefsDictionary);
            
            int i = 0;
            for (id key in self.userPreferences.prefsDictionary[@"BANKS"]) {
                //NSLog(@"bank %@ %@'s in dictionary", self.userPreferences.prefsDictionary[@"BANKS"][key], key);
                
                //название банка
                UILabel *myLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, scrollHeight + i*50, 280, 50)];
                myLabel.text = self.userPreferences.prefsDictionary[@"BANKS_NAMES"][key];
                [myLabel setFont:titleFont];
                [myLabel setTextColor:[self.userPreferences.prefsDictionary[@"BANKS"][key] isEqual:@"1"] ? self.titlecolor : self.titlecolorDis];
                myLabel.tag = [key integerValue];
                [self.contentview addSubview:myLabel];
                
                //переключатель
                UISwitch *mySwitch = [[UISwitch alloc] init];// initWithFrame:CGRectMake(0, 75 + i*50, 0, 0)];
                mySwitch.translatesAutoresizingMaskIntoConstraints = NO;  //This part hung me up --- doesn't work without it!!!!!!!!!!!!!!!!!!!!
                
                [mySwitch addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventValueChanged];
                mySwitch.tag = [key integerValue];
                [mySwitch setOnTintColor:[UIColor colorWithRed:(126/255.0) green:(211/255.0) blue:(33/255.0) alpha:1]];
                
                [self.contentview addSubview:mySwitch];
                
                NSLayoutConstraint *leadingConstraint= [NSLayoutConstraint constraintWithItem:mySwitch attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:mySwitch.superview attribute:NSLayoutAttributeRight multiplier:1.0 constant:-2];
                NSLayoutConstraint *topConstraint= [NSLayoutConstraint constraintWithItem:mySwitch attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:mySwitch.superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:scrollHeight + 5 + i*50];
                
                [self.contentview addConstraints:@[leadingConstraint,topConstraint]];
                
                //состояние переключателя
                [mySwitch setOn: [self.userPreferences.prefsDictionary[@"BANKS"][key] isEqual:@"1"] ? YES : NO];
                
                i++;
            }
            
            if (i > 0) {
                
                UILabel *helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, scrollHeight + i*50, 280, 30)];
                [helpLabel setFont:[UIFont systemFontOfSize:12.0]];
                [helpLabel setTextColor:[UIColor colorWithRed:(126/255.0) green:(211/255.0) blue:(33/255.0) alpha:1]];
                helpLabel.text = NSLocalizedString(@"HELP", @"HELP в настройках");
                [self.contentview addSubview:helpLabel];
                
                scrollHeight += (i+1)*50;
            }
        }
        
        self.scrollview.contentSize = CGSizeMake(self.scrollview.bounds.size.width, scrollHeight);
        self.contentHeight.constant = scrollHeight;

        NSLog(@"Content Height %ld",  (long)self.scrollview.contentSize.height);
        NSLog(@"ScrollView Height %ld",  (long)self.scrollview.frame.size.height);
       // NSLog(@"ContentView width %ld",  (long)self.contentview.frame.size.width);
        //NSLog(@"ContentView height %ld",  (long)self.contentview.frame.size.height);
        //NSLog(@"Scrolview width %ld",  (long)self.scrollview.frame.size.width);
        
    }];
    
    //устанавливаем зависимости между операциями
    [showOperation addDependency:readPrefsOperation];
    
    //добавляем операции в соответствующие очереди
    [mainQueue addOperation:showOperation];
    [myQueue addOperation:readPrefsOperation];

}


#pragma mark - IBAction buttons


- (void)changeCBRFSwitch:(UISwitch *)sender{
    
    if([sender isOn]){
        [self.userPreferences savePrefswithKey: @"CBRF" andValue:@"1"];
        [self applyLableColor:sender.tag state:YES];
        
    } else{
        [self.userPreferences savePrefswithKey: @"CBRF" andValue:@"0"];
        [self applyLableColor:sender.tag state:NO];
    }
    
}

- (void)changeSwitch:(UISwitch *)sender{
    
    if([sender isOn]){
        //NSLog(@"Switch is ON %ld", (long)sender.tag);
        [self.userPreferences savePrefswithBankKey: [NSString stringWithFormat:(@"%ld@"), (long)sender.tag] andValue:@"1" andBankName:nil];
        [self applyLableColor:sender.tag state:YES];

    } else{
        //NSLog(@"Switch is OFF %ld",  (long)sender.tag);
        [self.userPreferences savePrefswithBankKey: [NSString stringWithFormat:(@"%ld@"), (long)sender.tag] andValue:@"0" andBankName:nil];
        [self applyLableColor:sender.tag state:NO];
    }
    
}

- (void) applyLableColor:(long)tg state:(BOOL)vkl {

    NSArray *subviews = [self.contentview subviews];
    
    if ([subviews count] == 0) return;
    
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[UILabel class]] && subview.tag == tg) {
            //NSLog(@"%@", subview);
            
            [(UILabel*)subview setTextColor: (vkl ? self.titlecolor : self.titlecolorDis)];
            break;
        }
    }

}

- (IBAction)eurSwitch:(id)sender {
    [self.userPreferences savePrefswithKey:@"EUR" andValue:[sender isOn]  ? @"YES" : @"NO" ];

}

- (IBAction)usdSwitch:(id)sender {
    [self.userPreferences savePrefswithKey:@"USD" andValue:[sender isOn]  ? @"YES" : @"NO" ];
    
}

- (IBAction)actualSwitch:(id)sender {
    NSLog(@"ActualControl fired!!!!");
    NSString *switchVal = [NSString stringWithFormat:@"%ld", (long)self.actualControl.selectedSegmentIndex];
    NSLog(@"%@", switchVal);
     [self.userPreferences savePrefswithKey:@"SWITCH" andValue:switchVal];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
