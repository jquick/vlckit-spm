# VLCKit SPM

This is a Swift Package Manager compatible version of [VLCKit](https://code.videolan.org/videolan/VLCKit). 
It distributes and bundles VLCKit for iOS, macOS and tvOS as a single Swift Package. 

### Installation
Add this repo to as a Swift Package dependency to your project
```
https://github.com/tylerjonesio/vlckit-spm
```

If using this in a swift package, add this repo as a dependency.
```
.package(url: "https://github.com/tylerjonesio/vlckit-spm/", .upToNextMajor(from: "3.5.1"))
```

### Usage

To get started, import this library: `import VLCKitSPM`

See the [VLCKit documentation](https://videolan.videolan.me/VLCKit/) for more info on integration and usage for VLCKit.

#### Audio Callback Support

This package includes a Swift-friendly wrapper around `libvlc_audio_set_callbacks()` for monitoring audio levels and custom audio processing. This is particularly useful for RTSP stream monitoring.

**Quick Example:**
```swift
import VLCKitSPM

let player = VLCMediaPlayer()

// Monitor audio levels
let callbacks = VLCAudioCallbacks.forLevelMonitoring { level in
    print("RMS: \(level.rms), Peak: \(level.peak), dB: \(level.decibel)")
}

player.setAudioCallbacks(callbacks)
player.media = VLCMedia(url: URL(string: "rtsp://example.com/stream")!)
player.play()
```

See [EXAMPLE_AUDIO_LEVEL_MONITORING.md](./EXAMPLE_AUDIO_LEVEL_MONITORING.md) for detailed usage examples and important notes about audio playback behavior.

### Building
If you would like to bundle your own VLCKit binaries run the `generate.sh` script.
