import AVFoundation

struct VideoResolution: Equatable {
    let width: Int
    let height: Int
    let fps: Int
    let preset: AVCaptureSession.Preset
    
    var displayName: String {
        if width >= 3840 {
            return "4K at \(fps) fps"
        } else if width >= 1920 {
            return "1080p at \(fps) fps"
        } else if width >= 1280 {
            return "720p at \(fps) fps"
        } else {
            return "\(height)p at \(fps) fps"
        }
    }
    
    static let available4K30 = VideoResolution(width: 3840, height: 2160, fps: 30, preset: .hd4K3840x2160)
    static let available4K60 = VideoResolution(width: 3840, height: 2160, fps: 60, preset: .hd4K3840x2160)
    static let available1080p60 = VideoResolution(width: 1920, height: 1080, fps: 60, preset: .hd1920x1080)
    static let available1080p30 = VideoResolution(width: 1920, height: 1080, fps: 30, preset: .hd1920x1080)
    static let available720p60 = VideoResolution(width: 1280, height: 720, fps: 60, preset: .hd1280x720)
    static let available720p30 = VideoResolution(width: 1280, height: 720, fps: 30, preset: .hd1280x720)
    
    static func == (lhs: VideoResolution, rhs: VideoResolution) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height && lhs.fps == rhs.fps
    }
}
