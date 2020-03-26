//
//  TimeMachineiOSListController.m
//  TimeMachineiOS
//
//  Created by halo_michael on 26.03.2020.
//  Copyright (c) 2020 halo_michael. All rights reserved.
//

#import <Preferences/Preferences.h>
#import "Headers/SKListControllerProtocol.h"
#import "Headers/SKTintedListController.h"
#include <spawn.h>

void execCommand (const char* execPath, const char* args[]) {
    pid_t pid;
    int status;
    posix_spawn(&pid, execPath, NULL, NULL, (char* const*)args, NULL);
    waitpid(pid, &status, WEXITED);
}

void respring() {
    execCommand("/usr/bin/killall", (const char*[]){"killall", "-9", "SpringBoard", "backboardd", NULL});
}

@interface TimeMachineiOSListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation TimeMachineiOSListController

/*
 Want a tint color?
 -(UIColor*) tintColor { return [UIColor orangeColor]; }
 -(BOOL) tintNavigationTitleText { return NO; }
 */

-(NSString *)customTitle        { return @"TimeMachine iOS"; }

-(NSString *)headerText         { return @"TimeMachine iOS"; }
-(NSString *)headerTextFont     { return @"PingFangSC-Thin"; }
-(int)headerTextFontSize        { return 36; }

-(NSString *)headerSubText      { return @"TimeMachine on iOS\nby halo_michael"; }
-(NSString *)headerSubTextFont  { return @"PingFangSC-Thin"; }
-(int)headerSubTextFontSize     { return 15; }
-(BOOL)showHeartImage           { return NO; }

-(NSArray*) customSpecifiers
{
    return @[
        @{
            @"cell": @"PSGroupCell",
            @"label": @"TimeMachineiOS Settings"
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
            @"PostNotification": @"TimeMachineiOS/reloadSettings",
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
            @"PostNotification": @"TimeMachineiOS/reloadSettings",
        }
    ];
}
@end
