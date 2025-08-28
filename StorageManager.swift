import Foundation

class StorageManager {
    private let pathsToCheck = [
        "/private/var/mobile/Media/USBDRIVE",
        "/Volumes/USBDRIVE"
    ]
    
    var externalDriveURL: URL? {
        for path in pathsToCheck {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
    
    var internalDocumentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func isExternalDriveConnected() -> Bool {
        externalDriveURL != nil
    }
}