//
//  AudioCallbacks.swift
//  VLCKitSPM
//
//  Swift-friendly wrapper around libvlc_audio_set_callbacks
//

#if os(tvOS)
import TVVLCKit
#elseif os(iOS) && !targetEnvironment(macCatalyst)
import MobileVLCKit
#elseif os(macOS)
import VLCKit
#endif

import VLCAudioBridge
import Foundation

/// Audio level information
public struct AudioLevel {
    /// RMS (Root Mean Square) level, typically 0.0 to 1.0
    public let rms: Float
    
    /// Peak level, typically 0.0 to 1.0
    public let peak: Float
    
    /// Decibel level (dB)
    public let decibel: Float
    
    public init(rms: Float, peak: Float, decibel: Float) {
        self.rms = rms
        self.peak = peak
        self.decibel = decibel
    }
}

/// Callback for audio level monitoring
public typealias AudioLevelCallback = (AudioLevel) -> Void

/// Swift-friendly wrapper for libVLC audio callbacks
public class VLCAudioCallbacks {
    /// Audio play callback - called when audio should be played
    /// Parameters: userData, samples buffer, number of samples, presentation timestamp
    /// Returns: number of samples written, or -1 on error
    public typealias PlayCallback = (UnsafeMutableRawPointer?, UnsafeRawPointer?, UInt32, Int64) -> Int32
    
    /// Audio pause callback - called when audio should be paused
    /// Parameters: userData, presentation timestamp
    public typealias PauseCallback = (UnsafeMutableRawPointer?, Int64) -> Void
    
    /// Audio resume callback - called when audio should be resumed
    /// Parameters: userData, presentation timestamp
    public typealias ResumeCallback = (UnsafeMutableRawPointer?, Int64) -> Void
    
    /// Audio flush callback - called when audio buffer should be flushed
    /// Parameters: userData, presentation timestamp
    public typealias FlushCallback = (UnsafeMutableRawPointer?, Int64) -> Void
    
    /// Audio drain callback - called when audio should be drained
    /// Parameters: userData
    public typealias DrainCallback = (UnsafeMutableRawPointer?) -> Void
    
    var playCallback: PlayCallback?
    let pauseCallback: PauseCallback?
    let resumeCallback: ResumeCallback?
    let flushCallback: FlushCallback?
    let drainCallback: DrainCallback?
    let userData: UnsafeMutableRawPointer?
    
    /// Audio level monitoring callback - called during play callback with level information
    public var audioLevelCallback: AudioLevelCallback?
    
    /// Initialize audio callbacks
    /// - Parameters:
    ///   - play: Callback invoked when audio should be played (required for level monitoring)
    ///   - pause: Callback invoked when audio should be paused
    ///   - resume: Callback invoked when audio should be resumed
    ///   - flush: Callback invoked when audio buffer should be flushed
    ///   - drain: Callback invoked when audio should be drained
    ///   - userData: Optional user data pointer passed to callbacks
    ///   - audioLevelCallback: Optional callback for monitoring audio levels (works with play callback)
    public init(
        play: PlayCallback? = nil,
        pause: PauseCallback? = nil,
        resume: ResumeCallback? = nil,
        flush: FlushCallback? = nil,
        drain: DrainCallback? = nil,
        userData: UnsafeMutableRawPointer? = nil,
        audioLevelCallback: AudioLevelCallback? = nil
    ) {
        self.playCallback = play
        self.pauseCallback = pause
        self.resumeCallback = resume
        self.flushCallback = flush
        self.drainCallback = drain
        self.userData = userData
        self.audioLevelCallback = audioLevelCallback
    }
    
    /// Create audio callbacks optimized for level monitoring
    /// - Parameter levelCallback: Callback to receive audio level information
    /// - Returns: Configured VLCAudioCallbacks instance
    public static func forLevelMonitoring(levelCallback: @escaping AudioLevelCallback) -> VLCAudioCallbacks {
        // Create a temporary callback wrapper that will be retained
        class CallbackWrapper {
            let callback: AudioLevelCallback
            init(callback: @escaping AudioLevelCallback) {
                self.callback = callback
            }
        }
        
        let wrapper = CallbackWrapper(callback: levelCallback)
        let wrapperPtr = Unmanaged.passRetained(wrapper)
        
        // Set up play callback that analyzes audio and forwards to level callback
        let playCallback: PlayCallback = { (userData, samples, count, pts) -> Int32 in
            guard let samples = samples else { return -1 }
            guard let userData = userData else { return -1 }
            
            // Recover the wrapper
            let wrapper = Unmanaged<CallbackWrapper>.fromOpaque(userData).takeUnretainedValue()
            
            // Calculate audio levels
            let int16Samples = samples.assumingMemoryBound(to: Int16.self)
            let sampleCount = Int(count)
            
            var sumSquares: Double = 0.0
            var peak: Int16 = 0
            
            for i in 0..<sampleCount {
                let sample = abs(int16Samples[i])
                sumSquares += Double(sample * sample)
                if sample > peak {
                    peak = sample
                }
            }
            
            // Calculate RMS
            let rms = sqrt(sumSquares / Double(sampleCount))
            let rmsNormalized = Float(rms / Double(Int16.max))
            
            // Calculate peak normalized
            let peakNormalized = Float(peak) / Float(Int16.max)
            
            // Calculate dB (avoid log(0))
            let rmsDb = rmsNormalized > 0.0001 ? 20 * log10(rmsNormalized) : -96.0
            
            let level = AudioLevel(rms: rmsNormalized, peak: peakNormalized, decibel: rmsDb)
            wrapper.callback(level)
            
            // Return success - we're just monitoring, not actually playing
            return Int32(count)
        }
        
        let callbacks = VLCAudioCallbacks(
            play: playCallback,
            userData: wrapperPtr.toOpaque(),
            audioLevelCallback: levelCallback
        )
        
        return callbacks
    }
    
    /// Calculate audio level from sample buffer
    /// - Parameters:
    ///   - samples: Pointer to audio samples
    ///   - count: Number of samples
    /// - Returns: AudioLevel with RMS, peak, and dB values
    internal func calculateAudioLevel(samples: UnsafeRawPointer, count: UInt32) -> AudioLevel {
        // Assume 16-bit signed integer samples (most common)
        // You may need to adjust based on your audio format
        let int16Samples = samples.assumingMemoryBound(to: Int16.self)
        let sampleCount = Int(count)
        
        var sumSquares: Double = 0.0
        var peak: Int16 = 0
        
        for i in 0..<sampleCount {
            let sample = abs(int16Samples[i])
            sumSquares += Double(sample * sample)
            if sample > peak {
                peak = sample
            }
        }
        
        // Calculate RMS
        let rms = sqrt(sumSquares / Double(sampleCount))
        let rmsNormalized = Float(rms / Double(Int16.max))
        
        // Calculate peak normalized
        let peakNormalized = Float(peak) / Float(Int16.max)
        
        // Calculate dB (avoid log(0))
        let rmsDb = rmsNormalized > 0.0001 ? 20 * log10(rmsNormalized) : -96.0
        
        return AudioLevel(rms: rmsNormalized, peak: peakNormalized, decibel: rmsDb)
    }
}

/// Low-level function to set audio callbacks directly on a libvlc_media_player_t pointer
/// - Parameters:
///   - player: The libvlc_media_player_t pointer
///   - callbacks: The audio callbacks to use
public func setVLCAudioCallbacks(
    player: OpaquePointer,
    callbacks: VLCAudioCallbacks
) {
    // Create C callback wrappers that bridge to Swift closures
    var playWrapper: libvlc_audio_play_cb? = nil
    var pauseWrapper: libvlc_audio_pause_cb? = nil
    var resumeWrapper: libvlc_audio_resume_cb? = nil
    var flushWrapper: libvlc_audio_flush_cb? = nil
    var drainWrapper: libvlc_audio_drain_cb? = nil
    
    // Store callbacks in a retained object
    let retained = Unmanaged.passRetained(callbacks)
    let opaque = retained.toOpaque()
    
    if let playCallback = callbacks.playCallback {
        playWrapper = { (opaqueParam, samples, count, pts) -> Int32 in
            guard let opaqueParam = opaqueParam else { return -1 }
            let cb = Unmanaged<VLCAudioCallbacks>.fromOpaque(opaqueParam).takeUnretainedValue()
            guard let samples = samples else { return -1 }
            
            // Call the user's play callback (it may already handle level monitoring)
            return cb.playCallback?(opaqueParam, UnsafeRawPointer(samples), count, pts) ?? -1
        }
    }
    
    if let pauseCallback = callbacks.pauseCallback {
        pauseWrapper = { (opaqueParam, pts) in
            guard let opaqueParam = opaqueParam else { return }
            let cb = Unmanaged<VLCAudioCallbacks>.fromOpaque(opaqueParam).takeUnretainedValue()
            cb.pauseCallback?(opaqueParam, pts)
        }
    }
    
    if let resumeCallback = callbacks.resumeCallback {
        resumeWrapper = { (opaqueParam, pts) in
            guard let opaqueParam = opaqueParam else { return }
            let cb = Unmanaged<VLCAudioCallbacks>.fromOpaque(opaqueParam).takeUnretainedValue()
            cb.resumeCallback?(opaqueParam, pts)
        }
    }
    
    if let flushCallback = callbacks.flushCallback {
        flushWrapper = { (opaqueParam, pts) in
            guard let opaqueParam = opaqueParam else { return }
            let cb = Unmanaged<VLCAudioCallbacks>.fromOpaque(opaqueParam).takeUnretainedValue()
            cb.flushCallback?(opaqueParam, pts)
        }
    }
    
    if let drainCallback = callbacks.drainCallback {
        drainWrapper = { (opaqueParam) in
            guard let opaqueParam = opaqueParam else { return }
            let cb = Unmanaged<VLCAudioCallbacks>.fromOpaque(opaqueParam).takeUnretainedValue()
            cb.drainCallback?(opaqueParam)
        }
    }
    
    // Call libvlc_audio_set_callbacks directly
    libvlc_audio_set_callbacks(
        player,
        playWrapper,
        pauseWrapper,
        resumeWrapper,
        flushWrapper,
        drainWrapper,
        opaque
    )
}

/// Extension to set audio callbacks on VLCMediaPlayer
extension VLCMediaPlayer {
    /// Set audio callbacks for this media player
    /// - Parameter callbacks: The audio callbacks to use
    /// - Note: This method wraps the libvlc_audio_set_callbacks C function
    ///         It uses runtime introspection to access the underlying libvlc_media_player_t pointer
    public func setAudioCallbacks(_ callbacks: VLCAudioCallbacks) {
        // Access the underlying player pointer using Objective-C runtime
        // VLCMediaPlayer stores the pointer in an internal property
        var mp: OpaquePointer?
        
        // Try common property names used by VLCKit
        if let playerValue = self.value(forKey: "player") as? NSValue {
            playerValue.getValue(&mp)
        } else if let playerValue = self.value(forKey: "_player") as? NSValue {
            playerValue.getValue(&mp)
        } else if let playerValue = self.value(forKey: "instance") as? NSValue {
            playerValue.getValue(&mp)
        }
        
        guard let player = mp else {
            print("Warning: Could not access underlying libvlc_media_player_t pointer from VLCMediaPlayer")
            return
        }
        
        setVLCAudioCallbacks(player: player, callbacks: callbacks)
    }
    
    /// Get the underlying libvlc_media_player_t pointer
    /// - Returns: The opaque pointer to the libvlc media player, or nil if unavailable
    public func getMediaPlayerPointer() -> OpaquePointer? {
        var mp: OpaquePointer?
        
        if let playerValue = self.value(forKey: "player") as? NSValue {
            playerValue.getValue(&mp)
        } else if let playerValue = self.value(forKey: "_player") as? NSValue {
            playerValue.getValue(&mp)
        } else if let playerValue = self.value(forKey: "instance") as? NSValue {
            playerValue.getValue(&mp)
        }
        
        return mp
    }
}

