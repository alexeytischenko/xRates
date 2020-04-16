//
//  UserPrefs.m
//  ExRatesRus
//
//  Created by Alexey Tischenko on 24.06.15.
//  Copyright (c) 2015 Alexey Tishchenko. All rights reserved.
//

#import "UserPrefs.h"


@interface UserPrefs ()
    @property (strong, nonatomic) NSString *filePath;
@end

@implementation UserPrefs


-(instancetype) initWithPrefs {

    self = [super init];
    self.prefsDictionary = [self getPrefs];
    return self;
}

-(NSMutableDictionary *) getPrefs {
    
    NSMutableDictionary *st = [NSMutableDictionary dictionaryWithContentsOfFile:self.filePath];
    if (st == nil) {
        st = [NSMutableDictionary
                                dictionaryWithDictionary:@{
                                                           @"SWITCH" : @"",
                                                           @"CBRF" : @"1",
                                                           @"EUR" : @"",
                                                           @"USD" : @"",
                                                           @"BANKS" : [[NSMutableDictionary alloc] init],
                                                           @"BANKS_NAMES" : [[NSMutableDictionary alloc] init]
                                                           }];
        NSLog(@"Init new prefs:%@",st);
    }
    
    return st;

}

-(void) savePrefswithKey: (NSString *)key andValue : (NSString *)val {
    
    NSLog(@"savePrefswithKey fired!");
    
    NSMutableDictionary *st = [self getPrefs];
    [st setObject: val forKey:key];
    [st writeToFile:self.filePath atomically:YES];
    
    NSLog(@"Save UserPrefs: %@", st);
    
}

-(void) savePrefswithBankKey: (NSString *)key andValue : (NSString *)val andBankName: (NSString *)bName {
    
    NSMutableDictionary *st = [self getPrefs];
    [st[@"BANKS"] setObject: val forKey:key];
    if (bName != nil)   [st[@"BANKS_NAMES"] setObject: bName forKey:key];
    [st writeToFile:self.filePath atomically:YES];
    
    NSLog(@"Save UserPrefs: %@", st);
    
}


//путь к файлу с настройками
-(NSString *)filePath
{
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [path objectAtIndex:0];
    return [documentDirectory stringByAppendingPathComponent:@"xrates_options_feed"];
}

@end
