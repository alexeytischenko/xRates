//
//  FeedNavigationController.m
//  ExRatesRus
//
//  Created by Alexey Tischenko on 02.07.15.
//  Copyright (c) 2015 Alexey Tishchenko. All rights reserved.
//

#import "FeedNavigationController.h"
//#import "CJAMacros.h"

@interface FeedNavigationController ()

@end

@implementation FeedNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];

    //Navigation BAR
    
    //сдвигаем title ЛЕНТА вверх, чтобы выровнять с другими экранами
    CGFloat verticalOffset = 1;
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:verticalOffset forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance]setShadowImage:[[UIImage alloc] init]];
    

    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];

    [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                           NSForegroundColorAttributeName: [UIColor colorWithRed:(104/255.0) green:(104/255.0) blue:(113/255.0) alpha:1],
                                                           NSFontAttributeName: [UIFont systemFontOfSize:19.0]
                                                           }];
    
    
    //TAB BAR
    
    //внешний вид таб-бара
   [[UITabBar appearance] setTintColor:[UIColor colorWithRed:(126/255.0) green:(211/255.0) blue:(33/255.0) alpha:1]];
    //[[UITabBar appearance] setBackgroundColor: [UIColor whiteColor]];

    //убираем бордер
    //[[UITabBar appearance] setShadowImage:[[UIImage alloc] init]]; //remove tabbar border - next line is also needed
    //[[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]]; //remove tabbar border
    
    
    UIFont *cFont = [UIFont boldSystemFontOfSize:11.0];
    
    //set toolbar #0
        UITabBarItem *tabBarItem = [self.tabBarController.tabBar.items objectAtIndex:0];
        UIImage *unselectedImage = [UIImage imageNamed:@"menu-feed"];
        UIImage *selectedImage = [UIImage imageNamed:@"menu-feed-act"];
    if ([unselectedImage respondsToSelector:@selector(imageWithRenderingMode:)]) {
        [tabBarItem setImage: [unselectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    } else {
        // iOS 6 fallback: insert code to convert imaged if needed
        tabBarItem.image = unselectedImage;
    }
    
    [tabBarItem setSelectedImage: selectedImage];
    [tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -7)];
    [tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:(104/255.0) green:(104/255.0) blue:(113/255.0) alpha:1],
                                         NSFontAttributeName : cFont} forState:UIControlStateNormal];
    [tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:(126/255.0) green:(211/255.0) blue:(33/255.0) alpha:1],
                                         NSFontAttributeName : cFont} forState:UIControlStateSelected];
    
    //set toolbar#1
    UITabBarItem *tabBarItem1 = [self.tabBarController.tabBar.items objectAtIndex:1];
    unselectedImage = [UIImage imageNamed:@"menu-settings"];
    selectedImage = [UIImage imageNamed:@"menu-settings-act"];
    
    if ([unselectedImage respondsToSelector:@selector(imageWithRenderingMode:)]) {
        [tabBarItem1 setImage: [unselectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    } else {
        // iOS 6 fallback: insert code to convert imaged if needed
        tabBarItem1.image = unselectedImage;
    }
    [tabBarItem1 setSelectedImage: selectedImage];
    [tabBarItem1 setTitlePositionAdjustment:UIOffsetMake(0, -7)];
    [tabBarItem1 setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:(104/255.0) green:(104/255.0) blue:(113/255.0) alpha:1],
                                         NSFontAttributeName : cFont} forState:UIControlStateNormal];
    [tabBarItem1 setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:(126/255.0) green:(211/255.0) blue:(33/255.0) alpha:1],
                                         NSFontAttributeName : cFont} forState:UIControlStateSelected];
    
    //set toolbar#2
    UITabBarItem *tabBarItem2 = [self.tabBarController.tabBar.items objectAtIndex:2];
    unselectedImage = [UIImage imageNamed:@"menu-info"];
    selectedImage = [UIImage imageNamed:@"menu-info-act"];
    
    if ([unselectedImage respondsToSelector:@selector(imageWithRenderingMode:)]) {
        [tabBarItem2 setImage: [unselectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    } else {
        // iOS 6 fallback: insert code to convert imaged if needed
        tabBarItem2.image = unselectedImage;
    }
    [tabBarItem2 setSelectedImage: selectedImage];
    [tabBarItem2 setTitlePositionAdjustment:UIOffsetMake(0, -7)];
    [tabBarItem2 setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:(104/255.0) green:(104/255.0) blue:(113/255.0) alpha:1],
                                         NSFontAttributeName : cFont} forState:UIControlStateNormal];
    [tabBarItem2 setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:(126/255.0) green:(211/255.0) blue:(33/255.0) alpha:1],
                                         NSFontAttributeName : cFont} forState:UIControlStateSelected];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
