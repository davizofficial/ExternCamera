import Foundation

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
    
    private init() {}
}
