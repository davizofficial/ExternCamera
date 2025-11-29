import Foundation

enum StorageType {
    case `internal`
    case external
}

struct StorageInfo {
    let type: StorageType
    let name: String
    let path: String
    let isAvailable: Bool
}

class StorageManager {
    static let shared = StorageManager()
    
    // Path untuk USB drive di jailbroken device
    private let usbDrivePaths = [
        "/private/var/mobile/Media/USBDRIVE",
        "/var/mobile/Media/USBDRIVE",
        "/private/var/mobile/Media/ExternalStorage",
        "/var/mobile/Media/ExternalStorage"
    ]
    
    private init() {}
    
    var internalDocumentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func getAvailableStorages() -> [StorageInfo] {
        var storages: [StorageInfo] = []
        
        // Internal storage - selalu tersedia
        storages.append(StorageInfo(
            type: .internal,
            name: "Internal Storage",
            path: internalDocumentsURL.path,
            isAvailable: true
        ))
        
        // External storage - cek ketersediaan
        if let externalURL = getUSBDriveURL() {
            storages.append(StorageInfo(
                type: .external,
                name: "USB Drive",
                path: externalURL.path,
                isAvailable: true
            ))
        } else {
            storages.append(StorageInfo(
                type: .external,
                name: "External Storage",
                path: "Not Available",
                isAvailable: false
            ))
        }
        
        return storages
    }
    
    func getUSBDriveURL() -> URL? {
        let fm = FileManager.default
        
        // Cek semua possible path untuk USB drive
        for path in usbDrivePaths {
            if fm.fileExists(atPath: path) {
                var isDirectory: ObjCBool = false
                if fm.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
                    print("✅ USB Drive ditemukan di: \(path)")
                    return URL(fileURLWithPath: path)
                }
            }
        }
        
        print("❌ USB Drive tidak ditemukan")
        return nil
    }
    
    func isExternalStorageAvailable() -> Bool {
        return getUSBDriveURL() != nil
    }
    
    func getSaveDirectory(forExternal: Bool) -> URL {
        if forExternal {
            guard let usbURL = getUSBDriveURL() else {
                print("⚠️ External storage tidak tersedia, fallback ke internal")
                return internalDocumentsURL
            }
            
            let cameraDir = usbURL.appendingPathComponent("DCIM/ExternCamera", isDirectory: true)
            let fm = FileManager.default
            
            // Buat folder jika belum ada
            if !fm.fileExists(atPath: cameraDir.path) {
                do {
                    try fm.createDirectory(at: cameraDir, withIntermediateDirectories: true, attributes: nil)
                    print("✅ Folder dibuat di: \(cameraDir.path)")
                } catch {
                    print("❌ Gagal buat folder: \(error.localizedDescription)")
                    return internalDocumentsURL
                }
            }
            
            return cameraDir
        } else {
            // Internal storage
            let cameraDir = internalDocumentsURL.appendingPathComponent("DCIM", isDirectory: true)
            let fm = FileManager.default
            
            if !fm.fileExists(atPath: cameraDir.path) {
                try? fm.createDirectory(at: cameraDir, withIntermediateDirectories: true, attributes: nil)
            }
            
            return cameraDir
        }
    }
    
    func getStorageSpace(for type: StorageType) -> (total: Int64, free: Int64)? {
        let path: String
        
        switch type {
        case .internal:
            path = internalDocumentsURL.path
        case .external:
            guard let url = getUSBDriveURL() else { return nil }
            path = url.path
        }
        
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
            let total = attributes[.systemSize] as? Int64 ?? 0
            let free = attributes[.systemFreeSize] as? Int64 ?? 0
            return (total, free)
        } catch {
            return nil
        }
    }
}
