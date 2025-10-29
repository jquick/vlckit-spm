# Complete Usage Example for RTSP Audio Level Monitoring

Yes, you can include this package in Xcode and monitor audio levels from RTSP streams!

## Setup in Xcode

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/tylerjonesio/vlckit-spm`
3. Select your project target and add `VLCKitSPM` to it

## Complete Example Code

```swift
import VLCKitSPM
import Foundation

class RTSPAudioMonitor {
    private let player: VLCMediaPlayer
    private var audioLevels: [Float] = []
    
    init() {
        self.player = VLCMediaPlayer()
        setupAudioMonitoring()
    }
    
    func setupAudioMonitoring() {
        // Create callbacks for level monitoring
        let callbacks = VLCAudioCallbacks.forLevelMonitoring { [weak self] level in
            guard let self = self else { return }
            
            // Log audio levels
            print("Audio Level - RMS: \(String(format: "%.3f", level.rms)), " +
                  "Peak: \(String(format: "%.3f", level.peak)), " +
                  "dB: \(String(format: "%.1f", level.decibel))")
            
            // Store levels for analysis
            self.audioLevels.append(level.rms)
            
            // Check if audio is present
            if level.rms > 0.01 {
                print("✓ Audio detected in RTSP stream")
            } else {
                print("⚠ Low/no audio detected")
            }
        }
        
        // Set callbacks on the player
        player.setAudioCallbacks(callbacks)
    }
    
    func playRTSPStream(url: URL) {
        let media = VLCMedia(url: url)
        player.media = media
        player.play()
        
        print("Playing RTSP stream: \(url.absoluteString)")
        print("Monitoring audio levels...")
    }
    
    func stop() {
        player.stop()
    }
    
    // Get average audio level over time
    func getAverageLevel() -> Float {
        guard !audioLevels.isEmpty else { return 0.0 }
        return audioLevels.reduce(0, +) / Float(audioLevels.count)
    }
}

// Usage
let monitor = RTSPAudioMonitor()
monitor.playRTSPStream(url: URL(string: "rtsp://your-stream-url")!)

// Later, when done:
// monitor.stop()
```

## Key Points

✅ **Works with RTSP streams** - The callbacks will fire as audio frames are received from the RTSP stream

✅ **Real-time monitoring** - Audio levels are calculated and reported in real-time as the stream plays

✅ **Easy integration** - Just import `VLCKitSPM` and use the `VLCAudioCallbacks.forLevelMonitoring()` helper

⚠️ **Note about audio playback**: Using `forLevelMonitoring()` will monitor levels but audio won't play through speakers (this is by design - libvlc disables default audio when callbacks are set). If you need both monitoring AND playback, see the advanced examples in `EXAMPLE_AUDIO_LEVEL_MONITORING.md`.

## What You Get

- **RMS Level**: Average audio level (0.0 to 1.0)
- **Peak Level**: Maximum audio level (0.0 to 1.0)  
- **Decibel Level**: Audio level in dB (typically -96.0 to 0.0 dB)

These values update in real-time as your RTSP stream plays, allowing you to:
- Detect if audio is present
- Monitor audio quality
- Detect silent periods
- Analyze audio characteristics

