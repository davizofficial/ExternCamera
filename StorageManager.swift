import Foundation

class StorageManager {
    private let possibleSDCardPaths = [
        "/var/mobile/Media/external-storage",
        "/private/var/mobile/Media/SDCARD",
        "/Volumes/SDCARD",
        "/var/mobile/Media/USBDRIVE"
    ]
    
    var internalDocumentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    var sdCardURL: URL? {
        for path in possibleSDCardPaths {
            if FileManager.default.fileExists(atPath: path) {
                if canWriteToDirectory(at: path) {
                    return URL(fileURLWithPath: path)
                }
            }
        }
        return nil
    }
    
    private func canWriteToDirectory(at path: String) -> Bool {
        let testFile = "\(path)/.test_write"
        do {
            try "test".write(toFile: testFile, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testFile)
            return true
        } catch {
            return false
        }
    }
    
    func isSDCardConnected() -> Bool {
        sdCardURL != nil
    }
    
    func getSaveDirectory(forExternal: Bool) -> URL {
        if forExternal, let sdURL = sdCardURL {
            let cameraDir = sdURL.appendingPathComponent("KameraCustom", isDirectory: true)
            if !FileManager.default.fileExists(atPath: cameraDir.path) {
                try? FileManager.default.createDirectory(at: cameraDir, withIntermediateDirectories: true, attributes: nil)
            }
            return cameraDir
        } else {
            return internalDocumentsURL
        }
    }
}
