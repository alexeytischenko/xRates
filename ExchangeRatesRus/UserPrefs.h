//
//  UserPrefs.h
//  ExRatesRus
//
//  Created by Alexey Tischenko on 24.06.15.
//  Copyright (c) 2015 Alexey Tishchenko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserPrefs : NSObject

-(instancetype) initWithPrefs;
-(NSMutableDictionary *) getPrefs;
-(void) savePrefswithKey: (NSString *)key andValue : (NSString *)val;
-(void) savePrefswithBankKey: (NSString *)key andValue : (NSString *)val andBankName: (NSString *)bName;

@property (strong, nonatomic) NSMutableDictionary *prefsDictionary;

@end
