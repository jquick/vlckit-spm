//
//  VLCAudioBridge.h
//  VLCKitSPM
//
//  Bridging header for libvlc audio callback functions
//

#ifndef VLCAudioBridge_h
#define VLCAudioBridge_h

#include <stdint.h>

#if defined(__cplusplus)
extern "C" {
#endif

// Forward declarations for libvlc types
typedef struct libvlc_media_player_t libvlc_media_player_t;

// Audio callback function pointer types
// Play callback: returns number of samples written, or -1 on error
typedef int32_t (*libvlc_audio_play_cb)(void *data, const void *samples, unsigned count, int64_t pts);

// Pause callback
typedef void (*libvlc_audio_pause_cb)(void *data, int64_t pts);

// Resume callback
typedef void (*libvlc_audio_resume_cb)(void *data, int64_t pts);

// Flush callback
typedef void (*libvlc_audio_flush_cb)(void *data, int64_t pts);

// Drain callback
typedef void (*libvlc_audio_drain_cb)(void *data);

// libvlc_audio_set_callbacks function declaration
// This function is provided by libvlc, which is linked via VLCKit
extern void libvlc_audio_set_callbacks(libvlc_media_player_t *mp,
                                       libvlc_audio_play_cb play,
                                       libvlc_audio_pause_cb pause,
                                       libvlc_audio_resume_cb resume,
                                       libvlc_audio_flush_cb flush,
                                       libvlc_audio_drain_cb drain,
                                       void *opaque);

#if defined(__cplusplus)
}
#endif

#endif /* VLCAudioBridge_h */

