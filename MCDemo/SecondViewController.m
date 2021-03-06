//
//  SecondViewController.m
//  MCDemo
//
//  Created by Gabriel Theodoropoulos on 1/6/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "SecondViewController.h"
#import "AppDelegate.h"

#define SEQUENTIAL_SEND_TO_PEERS 1

@interface SecondViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSMutableArray *arrFiles;
@property (nonatomic, strong) NSString *selectedFile;
@property (nonatomic) NSInteger selectedRow;
@property (nonatomic) UIImage *play;
@property (nonatomic) UIImage *pause;



-(void)copySampleFilesToDocDirIfNeeded;
-(NSArray *)getAllDocDirFiles;
-(void)didStartReceivingResourceWithNotification:(NSNotification *)notification;
-(void)updateReceivingProgressWithNotification:(NSNotification *)notification;
-(void)didFinishReceivingResourceWithNotification:(NSNotification *)notification;

@end

@implementation SecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _nextPeerSendIndex=0;
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ( [_appDelegate master] == TRUE ) {
        [self copySampleFilesToDocDirIfNeeded];
    } else {
        // Deleting files in AppDelegate now, not needed here
        //[self deleteSampleFilesFromDocDir];
    }
    
    _arrFiles = [[NSMutableArray alloc] initWithArray:[self getAllDocDirFiles]];
    
    [_tblFiles setDelegate:self];
    [_tblFiles setDataSource:self];
    [_tblFiles reloadData];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDataWithNotification:)
                                                 name:@"MCDidReceiveDataNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didStartReceivingResourceWithNotification:)
                                                 name:@"MCDidStartReceivingResourceNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateReceivingProgressWithNotification:)
                                                 name:@"MCReceivingProgressNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishReceivingResourceWithNotification:)
                                                 name:@"didFinishReceivingResourceNotification"
                                               object:nil];
    _play = [UIImage imageNamed:@"play.png"];
    _pause = [UIImage imageNamed:@"pause.png"];
    
    if ( [_appDelegate master] == TRUE ) {
        [self initAudioPlayer];
    }
}

- (void) initAudioPlayer {
    if ( _audioPlayerInitialized == FALSE) {
        NSString *currentSong = [_arrFiles objectAtIndex:0];
        NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", _documentsDirectory, currentSong]];
        
        NSError *error;
        _audioPlayer = [[AVAudioPlayer alloc]
                        initWithContentsOfURL:url
                        error:&error];
        if (error)
        {
            NSLog(@"Error in audioPlayer: %@",
                  [error localizedDescription]);
        } else {
            _audioPlayer.delegate = self;
            [_audioPlayer prepareToPlay];
            
            _audioPlayerInitialized=TRUE;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([_appDelegate master] != TRUE) {
        self.playButton.hidden=YES;
        //self.playStatus.hidden=YES;
    }
    
    if ( [_appDelegate master] == TRUE && [_appDelegate fileTransferCompleted] != TRUE) {
        self.playButton.enabled=NO;
        //self.playStatus.enabled=NO;
    } else {
        self.playButton.enabled=YES;
        //self.playStatus.enabled=YES;
    }
    
    // List of files to send
    NSInteger numFiles=[_arrFiles count];
    
    // List of peers
    NSInteger numPeers=[[_appDelegate.mcManager.session connectedPeers] count];
    
    if (numPeers < 1) {
        NSLog(@"No peers");
    }
    
    // Send files to peers if master and if necessary
    if ( numFiles > 0 && numPeers > 0 && [_appDelegate master] == TRUE && [_appDelegate fileTransferCompleted] != TRUE && [_appDelegate fileTransferInProgress] != TRUE) {

#if(SEQUENTIAL_SEND_TO_PEERS)
        _nextPeerSendIndex=0;
        // Send to next peer
        [self sendToNextPeer];
#else
        // Send each file to every peer
        for (int i=0; i<numFiles; i++) {
            NSLog(@"File: %@", [_arrFiles objectAtIndex:i]);
 
            //int j=0;
            for (int j=0; j<numPeers; j++) {
                NSLog(@"Peer: %@", [[_appDelegate.mcManager.session connectedPeers] objectAtIndex:j]);
                
                [self sendFileToPeer:i peerIndex:j];
            }
        }
#endif
        [_appDelegate setFileTransferInProgress:TRUE];
    }
}

- (void) sendToNextPeer {
    NSInteger numPeers=[[_appDelegate.mcManager.session connectedPeers] count];

    if ( _nextPeerSendIndex < numPeers) {
        [self sendFileToPeer:0 peerIndex:_nextPeerSendIndex];
        _nextPeerSendIndex++;
    }
}

- (void)sendFileToPeer:(NSInteger)fileIndex peerIndex:(NSInteger)peerIndex {
    NSString *filename=[_arrFiles objectAtIndex:fileIndex];
    NSString *filePath = [_documentsDirectory stringByAppendingPathComponent:filename];
    //NSString *modifiedName = [NSString stringWithFormat:@"%@_%@", _appDelegate.mcManager.peerID.displayName, filename];
    NSString *modifiedName = [NSString stringWithFormat:@"%@", filename];
    NSURL *resourceURL = [NSURL fileURLWithPath:filePath];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSProgress *progress = [_appDelegate.mcManager.session sendResourceAtURL:resourceURL
                                                                        withName:modifiedName
                                                                          toPeer:[[_appDelegate.mcManager.session connectedPeers] objectAtIndex:peerIndex]
                                                           withCompletionHandler:^(NSError *error) {
                                                               if (error) {
                                                                   NSLog(@"Error: %@", [error localizedDescription]);
                                                               }
                                                               
                                                               else{
//                                                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"MCDemo"
//                                                                                                                   message:@"File was successfully sent."
//                                                                                                                  delegate:self
//                                                                                                         cancelButtonTitle:nil
//                                                                                                         otherButtonTitles:@"Great!", nil];
//                                                                   
//                                                                   [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
                                                                   
                                                                   [_arrFiles replaceObjectAtIndex:fileIndex withObject:filename];
                                                                   [_tblFiles performSelectorOnMainThread:@selector(reloadData)
                                                                                               withObject:nil
                                                                                            waitUntilDone:NO];
                                                                   
#if(SEQUENTIAL_SEND_TO_PEERS)
                                                                   // Send the file to the next peer
                                                                   [self sendToNextPeer];
#endif
                                                               }
                                                           }];
        
        //NSLog(@"*** %f", progress.fractionCompleted);
        
        [progress addObserver:self
                   forKeyPath:@"fractionCompleted"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    });
}


- (IBAction) buttonPressed: (id) sender {
    //if ([_appDelegate fileTransferCompleted] == TRUE ) {
        if (_audioPlayer.playing == TRUE)
        {
            [_audioPlayer pause];
            //send pause message
            
            //UIImage *play = [UIImage imageNamed:@"play.png"];
            //self.playButton.enabled = YES;
            [self.playButton setImage:_play forState:UIControlStateNormal];
        }
        else
        {
            [self sendMyMessage];
            //usleep(20000);
            [_audioPlayer play];
            //UIImage *pause = [UIImage imageNamed:@"play.png"];
            //self.playButton.enabled = YES;
            [self.playButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
            
        }
    }
//}

-(void)sendMyMessage//implement parameter here to know if message is off or on
    {
    //NSData *dataToSend = [self getDateTime];
    NSData *dataToSend = [@"s" dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *allPeers = _appDelegate.mcManager.session.connectedPeers;
    NSError *error;
    
    [_appDelegate.mcManager.session sendData:dataToSend
                                     toPeers:allPeers
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
}


-(NSDate*) getDateTime {
        //NSDateFormatter *formatter;
        //NSString *dateString;
        //formatter = [[NSDateFormatter alloc] init];
        //[formatter setDateFormat:@"HH:mm:ss"];
        //dateString = [formatter stringFromDate:[NSDate date]];
    
        NSTimeInterval delayBeforeStarting = -60 * 60 * 8 + 2;
        NSDate *dateNow = [NSDate date];
        NSDate *toStart = [dateNow dateByAddingTimeInterval:delayBeforeStarting];
        NSLog(@"Current data: %@,%@", dateNow, toStart);
        return toStart;
    }


-(void)didReceiveDataWithNotification:(NSNotification *)notification{
//    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];
//    NSString *peerDisplayName = peerID.displayName;
//    
//    NSData *receivedData = [[notification userInfo] objectForKey:@"data"];
//    NSString *receivedText = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    //[self initAudioPlayer];
    [_audioPlayer play];
    //[self.playStatus setText:@"PAUSE"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Private method implementation

-(void)copySampleFilesToDocDirIfNeeded{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _documentsDirectory = [[NSString alloc] initWithString:[paths objectAtIndex:0]];
    
    NSString *file1Path = [_documentsDirectory stringByAppendingPathComponent:@"falling.mp3"];
    NSString *file2Path = [_documentsDirectory stringByAppendingPathComponent:@"all.mp3"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    
    if (![fileManager fileExistsAtPath:file1Path] || ![fileManager fileExistsAtPath:file2Path]) {
        [fileManager copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"falling" ofType:@"mp3"]
                             toPath:file1Path
                              error:&error];
        
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            return;
        }
        
//        [fileManager copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"all" ofType:@"mp3"]
//                             toPath:file2Path
//                              error:&error];
//        
//        if (error) {
//            NSLog(@"%@", [error localizedDescription]);
//            return;
//        }
    }
}


-(void)deleteSampleFilesFromDocDir {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _documentsDirectory = [[NSString alloc] initWithString:[paths objectAtIndex:0]];
    
    NSString *file1Path = [_documentsDirectory stringByAppendingPathComponent:@"falling.mp3"];
    NSString *file2Path = [_documentsDirectory stringByAppendingPathComponent:@"all.mp3"];
    //NSString *file1Path = [_documentsDirectory stringByAppendingPathComponent:@"sample_file1.txt"];
    //NSString *file2Path = [_documentsDirectory stringByAppendingPathComponent:@"sample_file2.txt"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    
    if ([fileManager fileExistsAtPath:file1Path]) {
        [fileManager removeItemAtPath:file1Path error:&error];

        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            return;
        }
    }
    
    if ([fileManager fileExistsAtPath:file2Path]) {
        [fileManager removeItemAtPath:file2Path error:&error];

        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            return;
        }
    }
}


-(NSArray *)getAllDocDirFiles{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:_documentsDirectory error:&error];
    
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return nil;
    }
    
    return allFiles;
}


-(void)didStartReceivingResourceWithNotification:(NSNotification *)notification{
    [_arrFiles addObject:[notification userInfo]];
    [_tblFiles performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}


-(void)updateReceivingProgressWithNotification:(NSNotification *)notification{
    NSLog(@"updateReceivingProgressWithNotification: Index %ld", (_arrFiles.count - 1));

    if (_arrFiles.count > 0) {
        NSProgress *progress = [[notification userInfo] objectForKey:@"progress"];
        
        NSDictionary *dict = [_arrFiles objectAtIndex:(_arrFiles.count - 1)];
        NSDictionary *updatedDict = @{@"resourceName"  :   [dict objectForKey:@"resourceName"],
                                      @"peerID"        :   [dict objectForKey:@"peerID"],
                                      @"progress"      :   progress
                                      };
        
        
        
        [_arrFiles replaceObjectAtIndex:_arrFiles.count - 1
                             withObject:updatedDict];
        
        [_tblFiles performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }
}


-(void)didFinishReceivingResourceWithNotification:(NSNotification *)notification{
    NSDictionary *dict = [notification userInfo];
    
    NSURL *localURL = [dict objectForKey:@"localURL"];
    NSString *resourceName = [dict objectForKey:@"resourceName"];
    
    // _documentsDirectory is nill for some reason in peer. Creating from scratch
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _documentsDirectory = [[NSString alloc] initWithString:[paths objectAtIndex:0]];
    //
    
    NSString *destinationPath = [_documentsDirectory stringByAppendingPathComponent:resourceName];
    NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager copyItemAtURL:localURL toURL:destinationURL error:&error];
    
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    [_arrFiles removeAllObjects];
    _arrFiles = nil;
    _arrFiles = [[NSMutableArray alloc] initWithArray:[self getAllDocDirFiles]];
   
    // Initialize the audio player with the first song
    [self initAudioPlayer];
    
    [_tblFiles performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}


#pragma mark - UITableView Delegate and Datasource method implementation

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_arrFiles count];
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"cellForRowAtIndexPath: Row %ld", (long)indexPath.row);

    UITableViewCell *cell;
    NSString *testString=[_arrFiles objectAtIndex:indexPath.row];
    
    if ([[_arrFiles objectAtIndex:indexPath.row] isKindOfClass:[NSString class]]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdentifier"];
            //[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }
        
        cell.textLabel.text = [_arrFiles objectAtIndex:indexPath.row];
        cell.textLabel.font = [UIFont fontWithName:@"Futura" size:14.0];
    }
    else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"newFileCellIdentifier"];
        
        NSDictionary *dict = [_arrFiles objectAtIndex:indexPath.row];
        NSString *receivedFilename = [dict objectForKey:@"resourceName"];
        NSString *peerDisplayName = [[dict objectForKey:@"peerID"] displayName];
        NSProgress *progress = [dict objectForKey:@"progress"];
        
        [(UILabel *)[cell viewWithTag:100] setText:receivedFilename];
        [(UILabel *)[cell viewWithTag:200] setText:[NSString stringWithFormat:@"from %@", peerDisplayName]];
        [(UIProgressView *)[cell viewWithTag:300] setProgress:progress.fractionCompleted];
    }
    
    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"heightForRowAtIndexPath: Row %ld", (long)indexPath.row);

    return 60.0;
//    if ([[_arrFiles objectAtIndex:indexPath.row] isKindOfClass:[NSString class]]) {
//        return 60.0;
//    }
//    else{
//        return 80.0;
//    }
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

#pragma mark - UIActionSheet Delegate method implementation

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex != [[_appDelegate.mcManager.session connectedPeers] count]) {
        NSString *filePath = [_documentsDirectory stringByAppendingPathComponent:_selectedFile];
        NSString *modifiedName = [NSString stringWithFormat:@"%@_%@", _appDelegate.mcManager.peerID.displayName, _selectedFile];
        NSURL *resourceURL = [NSURL fileURLWithPath:filePath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSProgress *progress = [_appDelegate.mcManager.session sendResourceAtURL:resourceURL
                                                                            withName:modifiedName
                                                                              toPeer:[[_appDelegate.mcManager.session connectedPeers] objectAtIndex:buttonIndex]
                                                               withCompletionHandler:^(NSError *error) {
                                                                   if (error) {
                                                                       NSLog(@"Error: %@", [error localizedDescription]);
                                                                   }
                                                                   
                                                                   else{
                                                                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"MCDemo"
                                                                                                                       message:@"File was successfully sent."
                                                                                                                      delegate:self
                                                                                                             cancelButtonTitle:nil
                                                                                                             otherButtonTitles:@"Great!", nil];
                                                                       
                                                                       [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
                                                                       
                                                                       [_arrFiles replaceObjectAtIndex:_selectedRow withObject:_selectedFile];
                                                                       [_tblFiles performSelectorOnMainThread:@selector(reloadData)
                                                                                                   withObject:nil
                                                                                                waitUntilDone:NO];
                                                                   }
                                                               }];
            
            //NSLog(@"*** %f", progress.fractionCompleted);
            
            [progress addObserver:self
                       forKeyPath:@"fractionCompleted"
                          options:NSKeyValueObservingOptionNew
                          context:nil];
        });
    }
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    NSLog(@"observeValueForKeyPath: Path %@", keyPath);
    NSLog(@"observeValueForKeyPath: Row %@", (long)0);

    NSString *sendingMessage = [NSString stringWithFormat:@"%@ - Sending %.f%%",
                                @"falling.mp3",
                                //_selectedFile,
                                [(NSProgress *)object fractionCompleted] * 100
                                ];
    
    //[_arrFiles replaceObjectAtIndex:_selectedRow withObject:sendingMessage];
    [_arrFiles replaceObjectAtIndex:0 withObject:sendingMessage];
    
    [_tblFiles performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

@end
