import Foundation
import AVFoundation

class CameraSettings {
    static let shared = CameraSettings()
    
    private let defaults = UserDefaults.standard
    
    // Keys
    private let gridKey = "showGrid"
    private let hdrKey = "hdrEnabled"
    private let livePhotoKey = "livePhotoEnabled"
    private let saveToExternalKey = "saveToExternal"
    private let flashModeKey = "flashMode"
    private let timerModeKey = "timerMode"
    private let videoResolutionWidthKey = "videoResolutionWidth"
    private let videoResolutionHeightKey = "videoResolutionHeight"
    private let videoResolutionFpsKey = "videoResolutionFps"
    
    var showGrid: Bool {
        get { defaults.bool(forKey: gridKey) }
        set { defaults.set(newValue, forKey: gridKey) }
    }
    
    var hdrEnabled: Bool {
        get { defaults.bool(forKey: hdrKey) }
        set { defaults.set(newValue, forKey: hdrKey) }
    }
    
    var livePhotoEnabled: Bool {
        get { defaults.bool(forKey: livePhotoKey) }
        set { defaults.set(newValue, forKey: livePhotoKey) }
    }
    
    var saveToExternal: Bool {
        get { defaults.bool(forKey: saveToExternalKey) }
        set { defaults.set(newValue, forKey: saveToExternalKey) }
    }
    
    var flashMode: FlashMode {
        get {
            let raw = defaults.string(forKey: flashModeKey) ?? "Off"
            return FlashMode(rawValue: raw) ?? .off
        }
        set { defaults.set(newValue.rawValue, forKey: flashModeKey) }
    }
    
    var timerMode: TimerMode {
        get {
            let value = defaults.integer(forKey: timerModeKey)
            return TimerMode(rawValue: value) ?? .off
        }
        set { defaults.set(newValue.rawValue, forKey: timerModeKey) }
    }
    
    var videoResolution: VideoResolution {
        get {
            let width = defaults.integer(forKey: videoResolutionWidthKey)
            let height = defaults.integer(forKey: videoResolutionHeightKey)
            let fps = defaults.integer(forKey: videoResolutionFpsKey)
            
            if width == 0 {
                // Default: 1080p at 30 fps
                return VideoResolution.available1080p30
            }
            
            let preset: AVCaptureSession.Preset
            if width >= 3840 {
                preset = .hd4K3840x2160
            } else if width >= 1920 {
                preset = .hd1920x1080
            } else {
                preset = .hd1280x720
            }
            
            return VideoResolution(width: width, height: height, fps: fps, preset: preset)
        }
        set {
            defaults.set(newValue.width, forKey: videoResolutionWidthKey)
            defaults.set(newValue.height, forKey: videoResolutionHeightKey)
            defaults.set(newValue.fps, forKey: videoResolutionFpsKey)
        }
    }
    
    private init() {}
}
