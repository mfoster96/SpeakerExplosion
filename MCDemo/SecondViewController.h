//
//  SecondViewController.h
//  MCDemo
//
//  Created by Gabriel Theodoropoulos on 1/6/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioPlayer.h>


@interface SecondViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, AVAudioPlayerDelegate>
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
- (IBAction)playPauseAudio:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *tblFiles;
@property IBOutlet UIButton* playButton;
@property IBOutlet UILabel* playStatus;


@end
