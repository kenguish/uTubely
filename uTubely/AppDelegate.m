//
//  AppDelegate.m
//  uTubely
//
//  Created by Kenneth Anguish on 8/5/12.
//  Copyright (c) 2012 kenneth. All rights reserved.
//

#import "AppDelegate.h"
#import "JSONKit.h"
#import "HCYoutubeParser.h"

@implementation AppDelegate
@synthesize queue, urlTextField, downloadButton, connection, buffer, extractedURL;
@synthesize progressIndicator, statusTextField, percentageTextField, qtView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    queue = [[ASINetworkQueue alloc] init];
    
    // Insert code here to initialize your application
    [self.urlTextField setStringValue: @"http://www.youtube.com/watch?v=zaOn1u8wIT0&feature=related"];
    [self.statusTextField setStringValue: @"Click \"Start\""];
    [self.progressIndicator setIndeterminate: NO];
    [self.progressIndicator setDoubleValue: 0.0];
    
    [NSTimer scheduledTimerWithTimeInterval: 1.0f/10.0f target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if (self.qtView.movie != nil) {
        [self.qtView.movie stop];
    }
    
    return NSTerminateNow;
}


- (IBAction)downloadAction:(id)sender {
    
    if (downloadingFlag) {
        [r cancel];
        [r clearDelegatesAndCancel];

        [self.progressIndicator setIndeterminate: NO];
        [self.progressIndicator setDoubleValue: 0.0];

        [self.statusTextField setStringValue: @"Download stopped."];
        downloadingFlag = NO;
        
        [self.downloadButton setTitle: @"Go!"];

    } else {
        [self.statusTextField setStringValue: @"Loading the Youtube URL."];
        
        // stop movie first
        
        if (self.qtView.movie != nil) {
            [self.qtView.movie stop];
            
            self.qtView.movie = nil;
        }
        
        downloadingFlag = YES;

        
        NSDictionary *videos = [HCYoutubeParser h264videosWithYoutubeURL:[NSURL URLWithString: [self.urlTextField stringValue]]];
        
        if (videos != nil) {
            // fetch hd720 first?
            NSString *url = [videos objectForKey: @"hd720"];
            
            if (url == nil) {
                url = [videos objectForKey: @"medium"];
                
                if (url == nil) {
                    url = [videos objectForKey: @"small"];
                    
                    [self.statusTextField setStringValue: @"Downloading the Youtube URL in small format"];

                } else {
                    
                    [self.statusTextField setStringValue: @"Downloading the Youtube URL in medium format"];

                }
            } else {
                [self.statusTextField setStringValue: @"Downloading the Youtube URL in HD720 format"];

            }
            
            if (url != nil) {
                self.extractedURL = [NSURL URLWithString: url];
                
                NSLog(@"url: %@", url);
                
                // start fetching videos
                [self.progressIndicator setIndeterminate: NO];
                
                [self.downloadButton setTitle: @"Stop!"];
                
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"yyyy-MM-dd-hh-mma"];
                NSString *dateString = [dateFormat stringFromDate: [NSDate date]];
                [dateFormat release];
                
                NSString *randomFilename = [NSString stringWithFormat: @"download_%@", dateString];
                
                r = [ASIHTTPRequest requestWithURL: self.extractedURL];
                
                NSString *local_full_path = [ [NSString stringWithFormat: @"~/Desktop/%@.mp4", randomFilename] stringByExpandingTildeInPath];
                //NSLog(@"Saving to: %@", local_full_path);
                //NSLog(@"Saving to the parent folder: %@", [local_full_path stringByDeletingLastPathComponent]);
                [r setTimeOutSeconds: 10];
                
                [r setAllowResumeForFileDownloads: YES];
                [r setNumberOfTimesToRetryOnTimeout:0];
                [r setDownloadDestinationPath: local_full_path];
                [r setTemporaryFileDownloadPath: [NSString stringWithFormat: @"%@.download", local_full_path]];
                [r setDownloadProgressDelegate: self.progressIndicator];
                
                [r setShowAccurateProgress:YES];
                [r setDelegate: self];
                
                [r setCompletionBlock:^{
                    [self.statusTextField setStringValue: @"Download completed."];
                    
                    self.extractedURL = nil;
                    [self.progressIndicator setIndeterminate: YES];
                    
                    // play movie
                    NSError *error = nil;
                    QTMovie *movie = [[QTMovie alloc] initWithFile: [ [NSString stringWithFormat: @"~/Desktop/%@.mp4", randomFilename] stringByExpandingTildeInPath] error: &error];
                    if (error == nil) {
                        [self.qtView setMovie: movie];
                        
                        [movie release];
                        [[self.qtView movie] play];
                        
                        //[self.qtView play: nil];
                    } else {
                        NSLog(@"Unable to play video");
                    }
                    
                    [self.downloadButton setTitle: @"Go!"];
                    
                    downloadingFlag = NO;
                }];
                
                [r setFailedBlock:^{
                    [self.statusTextField setStringValue: @"Download failed."];
                    
                    // unset the current updateset
                    self.extractedURL = nil;
                    [self.progressIndicator setIndeterminate: YES];
                    
                    [self.downloadButton setTitle: @"Go!"];
                    
                    downloadingFlag = NO;
                }];
                
                [r startAsynchronous];

            } else {
                [self.statusTextField setStringValue: @"Unable to find any Youtube videos with the URL"];
                
                // unset the current updateset
                self.extractedURL = nil;
                [self.progressIndicator setIndeterminate: YES];
                
                [self.downloadButton setTitle: @"Go!"];
                
                downloadingFlag = NO;
            }
        } else {
            [self.statusTextField setStringValue: @"Unable to find any Youtube videos with the URL"];
            
            // unset the current updateset
            self.extractedURL = nil;
            [self.progressIndicator setIndeterminate: YES];
            
            [self.downloadButton setTitle: @"Go!"];
            
            downloadingFlag = NO;
        }
    }
}


- (void)updateProgress {
    //NSLog(@"- (void)updateProgress: %@", [NSString stringWithFormat: @"%.0f%%", [self.progressIndicator doubleValue] * 100.0 ]);
    [self.percentageTextField setStringValue: [NSString stringWithFormat: @"%.0f%%", [self.progressIndicator doubleValue] * 100.0  ]];
}


- (void)dealloc {
    [queue release], self.queue = nil;
    
    [super dealloc];
}

@end
