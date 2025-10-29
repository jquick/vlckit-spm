//
//  VLCAudioBridgeHelper.h
//  VLCKitSPM
//
//  Helper to access VLCMediaPlayer's internal libvlc_media_player_t pointer
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCMediaPlayer;

// Helper function to get the underlying libvlc_media_player_t pointer
// Uses Objective-C runtime to access internal VLCKit structure
void * _Nullable VLCGetMediaPlayerPointer(VLCMediaPlayer *player);

NS_ASSUME_NONNULL_END

