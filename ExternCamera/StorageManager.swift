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
    
    private var externalStorageURL: URL?
    
    private init() {
        // Scan untuk external storage saat init
        scanForExternalStorage()
    }
    
    var internalDocumentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // Scan untuk external storage (USB, SD Card, dll)
    private func scanForExternalStorage() {
        let fm = FileManager.default
        
        // Method 1: Cek mounted volumes
        if let volumes = try? fm.contentsOfDirectory(at: URL(fileURLWithPath: "/Volumes"), 
                                                      includingPropertiesForKeys: [.volumeNameKey, .volumeIsRemovableKey],
                                                      options: .skipsHiddenFiles) {
            for volume in volumes {
                if let resourceValues = try? volume.resourceValues(forKeys: [.volumeIsRemovableKey]),
                   let isRemovable = resourceValues.volumeIsRemovable,
                   isRemovable {
                    print("✅ External storage ditemukan: \(volume.path)")
                    externalStorageURL = volume
                    return
                }
            }
        }
        
        // Method 2: Cek /private/var/mobile/Media untuk external storage
        let possiblePaths = [
            "/private/var/mobile/Media/DCIM",  // Untuk Lightning to USB adapter
            "/var/mobile/Media/DCIM",
            "/private/var/mobile/Media/ExternalStorage",
            "/var/mobile/Media/ExternalStorage"
        ]
        
        for path in possiblePaths {
            if fm.fileExists(atPath: path) {
                var isDirectory: ObjCBool = false
                if fm.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
                    // Cek apakah bisa write (untuk memastikan ini external storage)
                    let testFile = URL(fileURLWithPath: path).appendingPathComponent(".test_write")
                    if (try? Data().write(to: testFile)) != nil {
                        try? fm.removeItem(at: testFile)
                        print("✅ External storage ditemukan di: \(path)")
                        externalStorageURL = URL(fileURLWithPath: path)
                        return
                    }
                }
            }
        }
        
        print("ℹ️ External storage tidak ditemukan - gunakan internal storage")
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
        scanForExternalStorage() // Refresh scan
        
        if let externalURL = externalStorageURL {
            storages.append(StorageInfo(
                type: .external,
                name: "External Storage",
                path: externalURL.path,
                isAvailable: true
            ))
        } else {
            storages.append(StorageInfo(
                type: .external,
                name: "External Storage",
                path: "Not Connected",
                isAvailable: false
            ))
        }
        
        return storages
    }
    
    func getUSBDriveURL() -> URL? {
        scanForExternalStorage() // Refresh scan
        return externalStorageURL
    }
    
    func isExternalStorageAvailable() -> Bool {
        scanForExternalStorage() // Refresh scan
        return externalStorageURL != nil
    }
    
    func getSaveDirectory(forExternal: Bool) -> URL {
        if forExternal {
            guard let externalURL = getUSBDriveURL() else {
                print("⚠️ External storage tidak tersedia, fallback ke internal")
                return getSaveDirectory(forExternal: false)
            }
            
            let cameraDir = externalURL.appendingPathComponent("ExternCamera", isDirectory: true)
            let fm = FileManager.default
            
            // Buat folder jika belum ada
            if !fm.fileExists(atPath: cameraDir.path) {
                do {
                    try fm.createDirectory(at: cameraDir, withIntermediateDirectories: true, attributes: nil)
                    print("✅ External folder dibuat: \(cameraDir.path)")
                } catch {
                    print("❌ Gagal buat folder external: \(error.localizedDescription)")
                    return getSaveDirectory(forExternal: false)
                }
            }
            
            return cameraDir
        } else {
            // Internal storage - gunakan Documents/ExternCamera
            let cameraDir = internalDocumentsURL.appendingPathComponent("ExternCamera", isDirectory: true)
            let fm = FileManager.default
            
            if !fm.fileExists(atPath: cameraDir.path) {
                do {
                    try fm.createDirectory(at: cameraDir, withIntermediateDirectories: true, attributes: nil)
                    print("✅ Internal folder dibuat: \(cameraDir.path)")
                } catch {
                    print("❌ Gagal buat folder internal: \(error)")
                }
            }
            
            return cameraDir
        }
    }
    
    // Refresh scan untuk external storage
    func refreshExternalStorage() {
        scanForExternalStorage()
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
