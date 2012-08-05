//
//  AppDelegate.h
//  uTubely
//
//  Created by Kenneth Anguish on 8/5/12.
//  Copyright (c) 2012 kenneth. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASIFormDataRequest.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"

#import <QTKit/QTKit.h>

static NSString* const kUserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3";
extern NSString* const LBYouTubePlayerControllerErrorDomain;
extern NSInteger const LBYouTubePlayerControllerErrorCodeInvalidHTML;
extern NSInteger const LBYouTubePlayerControllerErrorCodeNoStreamURL;
extern NSInteger const LBYouTubePlayerControllerErrorCodeNoJSONData;

typedef enum {
    LBYouTubePlayerQualitySmall       = 0,
    LBYouTubePlayerQualityMedium   = 1,
    LBYouTubePlayerQualityLarge    = 2,
} LBYouTubePlayerQuality;


@interface AppDelegate : NSObject <NSApplicationDelegate, ASIHTTPRequestDelegate,ASIProgressDelegate> {
    BOOL downloadingFlag;
    
    
    __block ASIHTTPRequest *r;
}

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, retain) ASINetworkQueue *queue;

@property (nonatomic, retain) IBOutlet NSTextField *urlTextField;
@property (nonatomic, retain) IBOutlet NSButton *downloadButton;


@property (nonatomic, retain) NSURLConnection* connection;
@property (nonatomic, retain) NSMutableData* buffer;
@property (nonatomic, retain) NSURL* extractedURL;

@property (nonatomic) LBYouTubePlayerQuality quality;

@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, retain) IBOutlet NSTextField *statusTextField;
@property (nonatomic, retain) IBOutlet NSTextField *percentageTextField;

@property (nonatomic, retain) IBOutlet QTMovieView *qtView;



- (IBAction)downloadAction:(id)sender;

@end
