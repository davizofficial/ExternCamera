import Foundation

class StorageManager {
    var internalDocumentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func getSDCardURL() -> URL? {
        let fm = FileManager.default
        let urls = fm.urls(for: .documentDirectory, in: .userDomainMask)
        
        for url in urls {
            let path = url.path.lowercased()
            if path.contains("sdcard") || path.contains("external-storage") {
                return url
            }
        }
        
        return nil
    }
    
    func isSDCardConnected() -> Bool {
        getSDCardURL() != nil
    }
    
    func getSaveDirectory(forExternal: Bool) -> URL {
        if forExternal, let sdURL = getSDCardURL() {
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
