//
//  BuatsaverView.m
//  Buatsaver
//
//  A screensaver view that plays a video file in a loop.
//  Supports both .mp4 and .mov video formats.
//

#import "BuatsaverView.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@implementation BuatsaverView {
    AVPlayerLayer *_playerLayer;
    AVPlayer *_player;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1 / 30.0];
        [self setupPlayer];
    }
    return self;
}

- (void)setupPlayer {
    self.wantsLayer = YES;
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *videoURL = [bundle URLForResource:@"video" withExtension:@"mp4"];
    
    if (!videoURL) {
        videoURL = [bundle URLForResource:@"video" withExtension:@"mov"];
    }
    
    if (!videoURL) {
        NSLog(@"Buatsaver: No video found in bundle");
        return;
    }
    
    _player = [AVPlayer playerWithURL:videoURL];
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    _player.muted = YES;
    
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = self.bounds;
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.layer addSublayer:_playerLayer];
    
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(playerItemDidReachEnd:)
               name:AVPlayerItemDidPlayToEndTimeNotification
             object:[_player currentItem]];
    
    [_player play];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *item = [notification object];
    [item seekToTime:kCMTimeZero completionHandler:nil];
}

- (void)startAnimation {
    [super startAnimation];
    [_player play];
}

- (void)stopAnimation {
    [super stopAnimation];
    [_player pause];
}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
}

- (void)setFrame:(NSRect)frame {
    [super setFrame:frame];
    if (_playerLayer) {
        _playerLayer.frame = self.bounds;
    }
}

- (BOOL)hasConfigureSheet {
    return NO;
}

- (NSWindow *)configureSheet {
    return nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
