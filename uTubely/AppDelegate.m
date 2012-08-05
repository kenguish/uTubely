//
//  AppDelegate.m
//  uTubely
//
//  Created by Kenneth Anguish on 8/5/12.
//  Copyright (c) 2012 kenneth. All rights reserved.
//

#import "AppDelegate.h"
#import "JSONKit.h"

@implementation AppDelegate
@synthesize queue, urlTextField, downloadButton, connection, buffer, extractedURL;
@synthesize progressIndicator, statusTextField, percentageTextField, qtView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    queue = [[ASINetworkQueue alloc] init];
    
    // Insert code here to initialize your application
    [self.urlTextField setStringValue: @"http://www.youtube.com/watch?v=QH2-TGUlwu4"];
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
        NSLog(@"Supposed to stop download");
        
        [r cancel];
        [r clearDelegatesAndCancel];

        [self.progressIndicator setIndeterminate: NO];
        [self.progressIndicator setDoubleValue: 0.0];

        [self.statusTextField setStringValue: @"Download stopped."];
        downloadingFlag = NO;
        
    } else {
        [self.statusTextField setStringValue: @"Loading the Youtube page."];
        
        // stop movie first
        
        if (self.qtView.movie != nil) {
            [self.qtView.movie stop];
            
            self.qtView.movie = nil;
        }
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:
                                        
                                        [NSURL URLWithString: [self.urlTextField stringValue]]
                                        ];
        [request setValue:(NSString *)kUserAgent forHTTPHeaderField:@"User-Agent"];

        self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [self.connection start];
        
        downloadingFlag = YES;
    }
}


#pragma mark -
#pragma mark NSURLConnectionDelegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSUInteger capacity;
    if (response.expectedContentLength != NSURLResponseUnknownLength) {
        capacity = response.expectedContentLength;
    }
    else {
        capacity = 0;
    }
    
    self.buffer = [[NSMutableData alloc] initWithCapacity:capacity];
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.buffer appendData:data];
}



-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self _closeConnection];
    
    [self.statusTextField setStringValue: @"Unable to download."];
    downloadingFlag = NO;
}
-(void)_closeConnection {
    [self.connection cancel];
    self.connection = nil;
    self.buffer = nil;
}

-(void)connectionDidFinishLoading:(NSURLConnection *) connection {
    NSString* html = [[NSString alloc] initWithData: self.buffer encoding:NSUTF8StringEncoding];
    [self _closeConnection];
    
    //NSLog(@"html: %@", html);
    
    if (html.length <= 0) {
        [self.statusTextField setStringValue: @"URL might be invalid."];
        downloadingFlag = NO;
        
        return;
    }
    
    NSError* error = nil;
    
    self.extractedURL = nil;
    self.extractedURL = [self _extractYouTubeURLFromFile:html error:&error];
    if (error) {
        [self.statusTextField setStringValue: @"URL might be invalid."];
        downloadingFlag = NO;
        
    } else {
        downloadingFlag = YES;
        
        //[self _didSuccessfullyExtractYouTubeURL:self.extractedURL];
        //[self _loadVideoWithContentOfURL:self.extractedURL];
        
        [self.statusTextField setStringValue: @"Downloading..."];
        
        if ( self.extractedURL != nil ) {
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
        }
    }
}

- (void)updateProgress {
    //NSLog(@"- (void)updateProgress: %@", [NSString stringWithFormat: @"%.0f%%", [self.progressIndicator doubleValue] * 100.0 ]);
    [self.percentageTextField setStringValue: [NSString stringWithFormat: @"%.0f%%", [self.progressIndicator doubleValue] * 100.0  ]];
}


-(NSString *)_unescapeString:(NSString *)string {
    // will cause trouble if you have "abc\\\\uvw"
    // \u   --->    \U
    NSString *esc1 = [string stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    
    // "    --->    \"
    NSString *esc2 = [esc1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    // \\"  --->    \"
    NSString *esc3 = [esc2 stringByReplacingOccurrencesOfString:@"\\\\\"" withString:@"\\\""];
    
    NSString *quoted = [[@"\"" stringByAppendingString:esc3] stringByAppendingString:@"\""];
    NSData *data = [quoted dataUsingEncoding:NSUTF8StringEncoding];
    
    //  NSPropertyListFormat format = 0;
    //  NSString *errorDescr = nil;
    NSString *unesc = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
    
    if ([unesc isKindOfClass:[NSString class]]) {
        // \U   --->    \u
        return [unesc stringByReplacingOccurrencesOfString:@"\\U" withString:@"\\u"];
    }
    
    return nil;
}


-(NSURL*)_extractYouTubeURLFromFile:(NSString *)html error:(NSError *__autoreleasing *)error {
    NSString *JSONStart = nil;
    NSString *JSONStartFull = @"ls.setItem('PIGGYBACK_DATA', \")]}'";
    NSString *JSONStartShrunk = [JSONStartFull stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([html rangeOfString:JSONStartFull].location != NSNotFound)
        JSONStart = JSONStartFull;
    else if ([html rangeOfString:JSONStartShrunk].location != NSNotFound)
        JSONStart = JSONStartShrunk;
    
    if (JSONStart != nil) {
        NSScanner* scanner = [NSScanner scannerWithString:html];
        [scanner scanUpToString:JSONStart intoString:nil];
        [scanner scanString:JSONStart intoString:nil];
        
        NSString *JSON = nil;
        [scanner scanUpToString:@"\");" intoString:&JSON];
        JSON = [self _unescapeString:JSON];
        NSError* decodingError = nil;
        NSDictionary* JSONCode = nil;
        
        // First try to invoke NSJSONSerialization (Thanks Mattt Thompson)
        
        id NSJSONSerializationClass = NSClassFromString(@"NSJSONSerialization");
        SEL NSJSONSerializationSelector = NSSelectorFromString(@"dataWithJSONObject:options:error:");
        if (NSJSONSerializationClass && [NSJSONSerializationClass respondsToSelector:NSJSONSerializationSelector]) {
            JSONCode = [NSJSONSerialization JSONObjectWithData:[JSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&decodingError];
        }
        else {
            JSONCode = [JSON objectFromJSONStringWithParseOptions:JKParseOptionNone error:&decodingError];
        }
        
        if (decodingError) {
            // Failed
            
            *error = decodingError;
        }
        else {
            // Success
            
            //NSLog(@"json: %@", [JSONCode objectForKey:@"content"]);
            
            NSArray* videos = [[[JSONCode objectForKey:@"content"] objectForKey:@"video"] objectForKey:@"fmt_stream_map"];
            //NSLog(@"videos: %@", videos);
            
            NSString* streamURL = nil;
            
            if (videos.count) {
                NSString* streamURLKey = @"url";
                
                if (self.quality == LBYouTubePlayerQualityLarge) {
                    streamURL = [[videos objectAtIndex:0] objectForKey:streamURLKey];
                }
                else if (self.quality == LBYouTubePlayerQualityMedium) {
                    unsigned int index = MIN(0, videos.count-2);
                    streamURL = [[videos objectAtIndex:index] objectForKey:streamURLKey];
                }
                else {
                    streamURL = [[videos lastObject] objectForKey:streamURLKey];
                }
            }
            
            if (streamURL) {
                return [NSURL URLWithString:streamURL];
            } else {
                NSLog(@"Couldn't find the stream URL.");
            }
        }
    }
    else {
        //NSLog(@"The JSON data could not be found.");
        
        downloadingFlag = NO;
    }
    
    return nil;
}

- (void)dealloc {
    [queue release], self.queue = nil;
    
    [super dealloc];
}

@end
