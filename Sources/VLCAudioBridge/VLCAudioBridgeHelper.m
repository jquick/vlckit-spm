//
//  VLCAudioBridgeHelper.m
//  VLCKitSPM
//
//  Helper to access VLCMediaPlayer's internal libvlc_media_player_t pointer
//

#import "VLCAudioBridgeHelper.h"
#import <objc/runtime.h>

#if TARGET_OS_TV
#import <TVVLCKit/TVVLCKit.h>
#elif TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import <MobileVLCKit/MobileVLCKit.h>
#elif TARGET_OS_MAC
#import <VLCKit/VLCKit.h>
#endif

void * _Nullable VLCGetMediaPlayerPointer(VLCMediaPlayer *player) {
    if (!player) {
        return NULL;
    }
    
    // Try to access the internal pointer using Objective-C runtime
    // VLCKit stores it in an instance variable, commonly named:
    // - _player
    // - _instance
    // - player
    
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList([VLCMediaPlayer class], &count);
    
    if (ivars) {
        for (unsigned int i = 0; i < count; i++) {
            Ivar ivar = ivars[i];
            const char *name = ivar_getName(ivar);
            const char *type = ivar_getTypeEncoding(ivar);
            
            // Look for pointer types that might be the libvlc_media_player_t pointer
            // The type encoding for a pointer is "^v" or similar
            if (name && type && (strstr(type, "^") != NULL || strstr(type, "*") != NULL)) {
                // Try to get the value
                @try {
                    void **ptrPtr = (void **)((uintptr_t)player + ivar_getOffset(ivar));
                    void *ptr = *ptrPtr;
                    
                    // If we got a non-null pointer, it might be our player
                    if (ptr != NULL) {
                        // Additional validation: check common ivar names
                        NSString *ivarName = [NSString stringWithUTF8String:name];
                        if ([ivarName isEqualToString:@"_player"] ||
                            [ivarName isEqualToString:@"_instance"] ||
                            [ivarName isEqualToString:@"player"] ||
                            [ivarName isEqualToString:@"instance"]) {
                            free(ivars);
                            return ptr;
                        }
                    }
                } @catch (NSException *exception) {
                    // Continue to next ivar
                }
            }
        }
        free(ivars);
    }
    
    // Fallback: try direct access with known common names
    @try {
        // Try _player
        Ivar ivar = class_getInstanceVariable([VLCMediaPlayer class], "_player");
        if (ivar) {
            void **ptrPtr = (void **)((uintptr_t)player + ivar_getOffset(ivar));
            void *ptr = *ptrPtr;
            if (ptr) return ptr;
        }
        
        // Try player (without underscore)
        ivar = class_getInstanceVariable([VLCMediaPlayer class], "player");
        if (ivar) {
            void **ptrPtr = (void **)((uintptr_t)player + ivar_getOffset(ivar));
            void *ptr = *ptrPtr;
            if (ptr) return ptr;
        }
        
        // Try _instance
        ivar = class_getInstanceVariable([VLCMediaPlayer class], "_instance");
        if (ivar) {
            void **ptrPtr = (void **)((uintptr_t)player + ivar_getOffset(ivar));
            void *ptr = *ptrPtr;
            if (ptr) return ptr;
        }
    } @catch (NSException *exception) {
        // Failed to access
    }
    
    return NULL;
}

