import Foundation

enum StorageType {
    case `internal`
    case external
}

struct StorageInfo {
    let type: StorageType
    let name: String
    let path: String
    let url: URL
    let isAvailable: Bool
    let isWritable: Bool
    let freeSpace: Int64?
    let totalSpace: Int64?
}

class StorageManager {
    static let shared = StorageManager()
    
    private var detectedStorages: [StorageInfo] = []
    private var selectedExternalURL: URL?
    
    private init() {
        // Scan untuk semua storage saat init
        scanAllStorages()
    }
    
    var internalDocumentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // SCAN SEMUA STORAGE YANG TERDETEKSI DI IPHONE
    func scanAllStorages() {
        let fm = FileManager.default
        var foundStorages: [StorageInfo] = []
        
        print("\n🔍 === SCANNING ALL STORAGES ===")
        
        // 1. INTERNAL STORAGE (selalu ada)
        let internalURL = internalDocumentsURL
        let internalSpace = getStorageSpace(at: internalURL)
        foundStorages.append(StorageInfo(
            type: .internal,
            name: "iPhone Internal",
            path: internalURL.path,
            url: internalURL,
            isAvailable: true,
            isWritable: true,
            freeSpace: internalSpace?.free,
            totalSpace: internalSpace?.total
        ))
        print("✅ Internal: \(internalURL.path)")
        
        // 2. SCAN /Volumes (untuk USB, SD Card yang di-mount iOS)
        let volumesPath = URL(fileURLWithPath: "/Volumes")
        if let volumes = try? fm.contentsOfDirectory(
            at: volumesPath,
            includingPropertiesForKeys: [.volumeNameKey, .volumeIsRemovableKey, .volumeIsLocalKey],
            options: [.skipsHiddenFiles]
        ) {
            print("\n📂 Scanning /Volumes...")
            for volume in volumes {
                let volumeName = volume.lastPathComponent
                let isWritable = testWriteAccess(at: volume)
                let space = getStorageSpace(at: volume)
                
                print("  📍 Found: \(volumeName) at \(volume.path)")
                print("     Writable: \(isWritable)")
                
                if isWritable {
                    foundStorages.append(StorageInfo(
                        type: .external,
                        name: volumeName,
                        path: volume.path,
                        url: volume,
                        isAvailable: true,
                        isWritable: true,
                        freeSpace: space?.free,
                        totalSpace: space?.total
                    ))
                    
                    // Set sebagai external storage pertama yang ditemukan
                    if selectedExternalURL == nil {
                        selectedExternalURL = volume
                    }
                }
            }
        }
        
        // 3. SCAN /private/var/mobile/Media (untuk external storage iOS)
        let mediaPaths = [
            "/private/var/mobile/Media",
            "/var/mobile/Media"
        ]
        
        print("\n📂 Scanning Media paths...")
        for mediaPath in mediaPaths {
            if fm.fileExists(atPath: mediaPath) {
                if let contents = try? fm.contentsOfDirectory(atPath: mediaPath) {
                    for item in contents {
                        let fullPath = "\(mediaPath)/\(item)"
                        var isDir: ObjCBool = false
                        
                        if fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue {
                            let url = URL(fileURLWithPath: fullPath)
                            let isWritable = testWriteAccess(at: url)
                            
                            print("  📍 Found: \(item) at \(fullPath)")
                            print("     Writable: \(isWritable)")
                            
                            // Hanya tambahkan jika writable dan bukan internal
                            if isWritable && !fullPath.contains("Documents") {
                                let space = getStorageSpace(at: url)
                                foundStorages.append(StorageInfo(
                                    type: .external,
                                    name: item,
                                    path: fullPath,
                                    url: url,
                                    isAvailable: true,
                                    isWritable: true,
                                    freeSpace: space?.free,
                                    totalSpace: space?.total
                                ))
                                
                                if selectedExternalURL == nil {
                                    selectedExternalURL = url
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // 4. SCAN root directories (untuk jailbroken devices)
        let rootPaths = [
            "/var/mobile/Media/DCIM",
            "/User/Media"
        ]
        
        print("\n📂 Scanning root paths...")
        for rootPath in rootPaths {
            if fm.fileExists(atPath: rootPath) {
                let url = URL(fileURLWithPath: rootPath)
                let isWritable = testWriteAccess(at: url)
                
                print("  📍 Found: \(rootPath)")
                print("     Writable: \(isWritable)")
                
                if isWritable {
                    let space = getStorageSpace(at: url)
                    foundStorages.append(StorageInfo(
                        type: .external,
                        name: url.lastPathComponent,
                        path: rootPath,
                        url: url,
                        isAvailable: true,
                        isWritable: true,
                        freeSpace: space?.free,
                        totalSpace: space?.total
                    ))
                    
                    if selectedExternalURL == nil {
                        selectedExternalURL = url
                    }
                }
            }
        }
        
        detectedStorages = foundStorages
        
        print("\n✅ Total storage ditemukan: \(foundStorages.count)")
        print("=================================\n")
    }
    
    // Test apakah bisa write ke storage
    private func testWriteAccess(at url: URL) -> Bool {
        let testFile = url.appendingPathComponent(".externcamera_test")
        let testData = Data("test".utf8)
        
        do {
            try testData.write(to: testFile)
            try? FileManager.default.removeItem(at: testFile)
            return true
        } catch {
            return false
        }
    }
    
    // Get storage space info
    private func getStorageSpace(at url: URL) -> (total: Int64, free: Int64)? {
        do {
            let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            let total = values.volumeTotalCapacity.map { Int64($0) } ?? 0
            let free = values.volumeAvailableCapacity.map { Int64($0) } ?? 0
            return (total, free)
        } catch {
            return nil
        }
    }
    
    func getAvailableStorages() -> [StorageInfo] {
        scanAllStorages() // Refresh scan
        return detectedStorages
    }
    
    func getUSBDriveURL() -> URL? {
        return selectedExternalURL
    }
    
    func isExternalStorageAvailable() -> Bool {
        return selectedExternalURL != nil
    }
    
    // Set external storage URL secara manual
    func setExternalStorage(url: URL) {
        selectedExternalURL = url
        print("✅ External storage set to: \(url.path)")
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
        scanAllStorages()
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
