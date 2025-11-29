import Foundation

enum CameraMode: String, CaseIterable {
    case photo = "PHOTO"
    case video = "VIDEO"
    case square = "SQUARE"
    case pano = "PANO"
}

enum FlashMode: String {
    case auto = "Auto"
    case on = "On"
    case off = "Off"
}

enum TimerMode: Int {
    case off = 0
    case three = 3
    case ten = 10
}
