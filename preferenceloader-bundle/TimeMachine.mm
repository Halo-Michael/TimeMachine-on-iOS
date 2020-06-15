//
//  TimeMachineListController.m
//  TimeMachine
//
//  Created by halo_michael on 26.03.2020.
//  Copyright (c) 2020 halo_michael. All rights reserved.
//

#import <Preferences/PSBundleController.h>
#import <Preferences/PSControlTableCell.h>
#import <Preferences/PSDiscreteSlider.h>
#import <Preferences/PSEditableTableCell.h>
#import <Preferences/PSHeaderFooterView.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSListItemsController.h>
#import <Preferences/PSRootController.h>
#import <Preferences/PSSliderTableCell.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>
#import <Preferences/PSSystemPolicyForApp.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSViewController.h>
#import <Preferences/PreferencesAppController.h>
#import "Headers/SKListControllerProtocol.h"
#import "Headers/SKTintedListController.h"
#import <stdlib.h>

@interface TimeMachineListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation TimeMachineListController

/*
 Want a tint color?
 -(UIColor*) tintColor { return [UIColor orangeColor]; }
 -(BOOL) tintNavigationTitleText { return NO; }
 */

-(NSString *)customTitle        { return @"TimeMachine on iOS"; }

-(NSString *)headerText         { return @"TimeMachine on iOS"; }
-(NSString *)headerTextFont     { return @"PingFangSC-Thin"; }
-(int)headerTextFontSize        { return 36; }

-(NSString *)headerSubText      { return @"by @halo_michael\nUI by XCXiao"; }
-(NSString *)headerSubTextFont  { return @"PingFangSC-Thin"; }
-(int)headerSubTextFontSize     { return 15; }
-(BOOL)showHeartImage           { return NO; }

-(NSArray*) customSpecifiers
{
    return @[
        @{
            @"cell": @"PSGroupCell",
            @"label": @"TimeMachine on iOS Settings"
        },
        @{
            @"cell": @"PSGroupCell",
            @"label": @"MAX_ROOTFS_SNAPSHOT",
            @"footerText": @"MAX_ROOTFS_SNAPSHOT_DESCRIPTION"
        },
        @{
            @"cell": @"PSSliderCell",
            @"default": @3,
            @"defaults": @"com.michael.TimeMachine",
            @"showValue": @YES,
            @"isContinuous": @NO,
            @"isSegmented": @YES,
            @"segmentCount": @10,
            @"min": @0,
            @"max": @10,
            @"key": @"max_rootfs_snapshot",
            @"PostNotification": @"TimeMachine-on-iOS/reloadSettings",
        },
        @{
            @"cell": @"PSGroupCell",
            @"label": @"MAX_DATAFS_SNAPSHOT",
            @"footerText": @"MAX_DATAFS_SNAPSHOT_DESCRIPTION"
        },
        @{
            @"cell": @"PSSliderCell",
            @"default": @3,
            @"defaults": @"com.michael.TimeMachine",
            @"showValue": @YES,
            @"isContinuous": @NO,
            @"isSegmented": @YES,
            @"segmentCount": @10,
            @"min": @0,
            @"max": @10,
            @"key": @"max_datafs_snapshot",
            @"PostNotification": @"TimeMachine-on-iOS/reloadSettings",
        }
    ];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [super setPreferenceValue:value specifier:specifier];

    if([specifier.properties[@"key"] isEqualToString:@"max_rootfs_snapshot"]) {
        system([[NSString stringWithFormat:@"setTimeMachine -f / -n %@", value] UTF8String]);
    }

    if([specifier.properties[@"key"] isEqualToString:@"max_datafs_snapshot"]) {
        system([[NSString stringWithFormat:@"setTimeMachine -f /var -n %@", value] UTF8String]);
    }
}
@end
