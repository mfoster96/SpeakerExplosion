//
//  SecondViewController.h
//  MCDemo
//
//  Created by Gabriel Theodoropoulos on 1/6/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioPlayer.h>


@interface SecondViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
    
    UIButton *button_PlaySound;
    AVAudioPlayer *audioPlayer;
}

@property (nonatomic, retain) IBOutlet UIButton *button_PlaySound;
@property (weak, nonatomic) IBOutlet UITableView *tblFiles;


@end
