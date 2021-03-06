//
//  SecondViewController.h
//  MCDemo
//
//  Created by Gabriel Theodoropoulos on 1/6/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioPlayer.h>


@interface SecondViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, AVAudioPlayerDelegate> {
    NSUInteger _nextPeerSendIndex;
    BOOL _audioPlayerInitialized;
}
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (weak, nonatomic) IBOutlet UITableView *tblFiles;
@property IBOutlet UIButton* playButton;
@property(readwrite, assign) NSUInteger nextPeerSendIndex;
@property(readwrite, assign) BOOL audioPlayerInitialized;


@end
