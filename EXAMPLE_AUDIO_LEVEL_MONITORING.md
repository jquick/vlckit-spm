# Audio Level Monitoring Example

This example shows how to use the audio callback wrapper to monitor audio levels when playing RTSP streams.

## Quick Start

```swift
import VLCKitSPM

// Create a media player
let player = VLCMediaPlayer()

// Set up audio level monitoring
let callbacks = VLCAudioCallbacks.forLevelMonitoring { level in
    print("Audio Level - RMS: \(level.rms), Peak: \(level.peak), dB: \(level.decibel)")
    
    // You can also check if audio is present
    if level.rms > 0.01 {
        print("Audio detected!")
    } else {
        print("No audio detected")
    }
}

// Set the callbacks on the player
player.setAudioCallbacks(callbacks)

// Load and play an RTSP stream
let media = VLCMedia(url: URL(string: "rtsp://example.com/stream")!)
player.media = media
player.play()
```

## Advanced Usage

If you need more control, you can provide your own play callback:

```swift
let callbacks = VLCAudioCallbacks(
    play: { (userData, samples, count, pts) -> Int32 in
        // Analyze audio levels
        guard let samples = samples else { return -1 }
        
        // Your custom audio processing here
        // ...
        
        // Return number of samples processed
        return Int32(count)
    },
    audioLevelCallback: { level in
        // Receive calculated audio levels
        print("RMS: \(level.rms), Peak: \(level.peak), dB: \(level.decibel)")
    }
)

player.setAudioCallbacks(callbacks)
```

## Callbacks Available

The audio callback system provides these callbacks for RTSP stream monitoring:

1. **Play Callback** - Called for each audio buffer, useful for:
   - Monitoring audio levels (RMS, peak, dB)
   - Detecting audio presence
   - Analyzing audio quality
   - Custom audio processing

2. **Pause Callback** - Called when playback pauses

3. **Resume Callback** - Called when playback resumes

4. **Flush Callback** - Called when audio buffer needs to be flushed

5. **Drain Callback** - Called to drain remaining audio

## Audio Level Information

The `AudioLevel` struct provides:
- `rms`: Root Mean Square level (0.0 to 1.0)
- `peak`: Peak level (0.0 to 1.0)
- `decibel`: Decibel level (typically -96.0 to 0.0 dB)

## Important Notes

### Audio Playback Behavior

**Important**: When you set audio callbacks using `libvlc_audio_set_callbacks()`, VLCKit disables its default audio output. This means:

1. **For monitoring only** (no audio playback): Use `forLevelMonitoring()` - it analyzes levels and returns success, but audio won't play through speakers.

2. **For monitoring while playing**: You need to provide a play callback that:
   - Analyzes audio levels
   - Also outputs audio to the system audio APIs (e.g., AudioQueue, CoreAudio)

Example for monitoring while playing:
```swift
let callbacks = VLCAudioCallbacks(
    play: { (userData, samples, count, pts) -> Int32 in
        // Analyze for levels
        if let levelCallback = /* get your callback */ {
            let level = /* calculate level */
            levelCallback(level)
        }
        
        // Also play audio yourself using AudioQueue/CoreAudio
        // audioQueue.enqueue(samples, count)
        
        return Int32(count)
    }
)
```

### Audio Format

- The play callback receives raw audio samples
- For RTSP streams, audio levels will be reported as audio frames are received
- The sample format is assumed to be 16-bit signed integers (most common for RTSP streams)
- Make sure to handle the case where audio might not be present initially

