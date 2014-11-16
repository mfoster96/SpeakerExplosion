//
//  AppDelegate.h
//  MCDemo
//
//  Created by Gabriel Theodoropoulos on 1/6/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {

    bool _connectionsEstablished;
    bool _fileTransferInProgress;
    bool _fileTransferCompleted;
    bool _master;
}

@property(readwrite, assign) bool connectionsEstablished;
@property(readwrite, assign) bool fileTransferInProgress;
@property(readwrite, assign) bool fileTransferCompleted;
@property(readwrite, assign) bool master;

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) MCManager *mcManager;

@end
