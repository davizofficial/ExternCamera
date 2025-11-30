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
        // Load bookmark dulu jika ada
        loadExternalStorageFromBookmark()
        
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
        
        // 1.5. SCAN MOUNTED VOLUMES MENGGUNAKAN FileManager.mountedVolumeURLs
        print("\n📂 Scanning mounted volumes...")
        if let mountedVolumes = fm.mountedVolumeURLs(includingResourceValuesForKeys: [
            .volumeNameKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey,
            .volumeIsLocalKey
        ], options: []) {
            for volume in mountedVolumes {
                do {
                    let resourceValues = try volume.resourceValues(forKeys: [
                        .volumeNameKey,
                        .volumeIsRemovableKey,
                        .volumeIsEjectableKey,
                        .volumeIsLocalKey
                    ])
                    
                    let volumeName = resourceValues.volumeName ?? volume.lastPathComponent
                    let isRemovable = resourceValues.volumeIsRemovable ?? false
                    let isEjectable = resourceValues.volumeIsEjectable ?? false
                    
                    print("  📍 Volume: \(volumeName)")
                    print("     Path: \(volume.path)")
                    print("     Removable: \(isRemovable), Ejectable: \(isEjectable)")
                    
                    // Cek apakah ini external storage (removable atau ejectable)
                    if isRemovable || isEjectable {
                        let isWritable = testWriteAccess(at: volume)
                        print("     Writable: \(isWritable)")
                        
                        if isWritable {
                            let space = getStorageSpace(at: volume)
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
                            
                            if selectedExternalURL == nil {
                                selectedExternalURL = volume
                                print("     ✅ Set as default external storage")
                            }
                        }
                    }
                } catch {
                    print("  ⚠️ Error reading volume properties: \(error)")
                }
            }
        }
        
        // 2. SCAN /Volumes (untuk USB, SD Card yang di-mount iOS)
        let volumesPaths = [
            "/Volumes",
            "/private/var/mobile/Library/LiveFiles/com.apple.filesystems.userfsd"
        ]
        
        for volumesPathString in volumesPaths {
            let volumesPath = URL(fileURLWithPath: volumesPathString)
            if let volumes = try? fm.contentsOfDirectory(
                at: volumesPath,
                includingPropertiesForKeys: [.volumeNameKey, .volumeIsRemovableKey, .volumeIsLocalKey],
                options: [.skipsHiddenFiles]
            ) {
                print("\n📂 Scanning \(volumesPathString)...")
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
        
        // Add bookmarked storage if exists and not already in list
        if let bookmarkedURL = selectedExternalURL {
            let alreadyExists = detectedStorages.contains { $0.url.path == bookmarkedURL.path }
            
            if !alreadyExists {
                let space = getStorageSpace(at: bookmarkedURL)
                let bookmarkedStorage = StorageInfo(
                    type: .external,
                    name: "📁 \(bookmarkedURL.lastPathComponent)",
                    path: bookmarkedURL.path,
                    url: bookmarkedURL,
                    isAvailable: true,
                    isWritable: testWriteAccess(at: bookmarkedURL),
                    freeSpace: space?.free,
                    totalSpace: space?.total
                )
                detectedStorages.insert(bookmarkedStorage, at: 1) // Insert after internal storage
            }
        }
        
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
    
    // Debug function untuk print semua path yang dicoba
    func debugPrintAllPaths() {
        print("\n🔍 === DEBUG: ALL ATTEMPTED PATHS ===")
        
        let fm = FileManager.default
        
        // Print mounted volumes
        if let volumes = fm.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: []) {
            print("\n📂 Mounted Volumes:")
            for volume in volumes {
                print("  - \(volume.path)")
                
                // Try to list contents
                if let contents = try? fm.contentsOfDirectory(atPath: volume.path) {
                    for item in contents.prefix(10) {
                        print("    └─ \(item)")
                    }
                    if contents.count > 10 {
                        print("    └─ ... and \(contents.count - 10) more items")
                    }
                }
            }
        }
        
        // Print common paths
        let pathsToCheck = [
            "/Volumes",
            "/private/var/mobile/Library/LiveFiles",
            "/private/var/mobile/Library/LiveFiles/com.apple.filesystems.userfsd",
            "/private/var/mobile/Media",
            "/var/mobile/Media",
            "/var/mobile/Library",
            "/private/var/mobile/Library"
        ]
        
        print("\n📂 Checking common paths:")
        for path in pathsToCheck {
            let exists = fm.fileExists(atPath: path)
            print("  - \(path): \(exists ? "✅ EXISTS" : "❌ NOT FOUND")")
            
            if exists {
                if let contents = try? fm.contentsOfDirectory(atPath: path) {
                    for item in contents.prefix(5) {
                        let fullPath = "\(path)/\(item)"
                        var isDir: ObjCBool = false
                        fm.fileExists(atPath: fullPath, isDirectory: &isDir)
                        print("    └─ \(item) \(isDir.boolValue ? "[DIR]" : "[FILE]")")
                    }
                    if contents.count > 5 {
                        print("    └─ ... and \(contents.count - 5) more items")
                    }
                }
            }
        }
        
        // Try to access Documents directory and see what's accessible
        print("\n📂 App Sandbox Info:")
        print("  - Documents: \(internalDocumentsURL.path)")
        print("  - Tmp: \(NSTemporaryDirectory())")
        print("  - Home: \(NSHomeDirectory())")
        
        print("\n=================================\n")
    }
    
    // Fungsi untuk set external storage dari URL yang dipilih user via document picker
    func setExternalStorageFromBookmark(url: URL) -> Bool {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Cannot access security-scoped resource")
            return false
        }
        
        // Test write access
        let testFile = url.appendingPathComponent(".externcamera_test")
        let testData = Data("test".utf8)
        
        do {
            try testData.write(to: testFile)
            try? FileManager.default.removeItem(at: testFile)
            
            // Save bookmark for persistent access
            do {
                let bookmarkData = try url.bookmarkData(
                    options: .minimalBookmark,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(bookmarkData, forKey: "externalStorageBookmark")
                
                selectedExternalURL = url
                print("✅ External storage set and bookmarked: \(url.path)")
                
                // Don't stop accessing - we need continuous access
                // url.stopAccessingSecurityScopedResource()
                
                return true
            } catch {
                print("❌ Failed to create bookmark: \(error)")
                url.stopAccessingSecurityScopedResource()
                return false
            }
        } catch {
            print("❌ Cannot write to selected location: \(error)")
            url.stopAccessingSecurityScopedResource()
            return false
        }
    }
    
    // Load external storage dari bookmark yang tersimpan
    func loadExternalStorageFromBookmark() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: "externalStorageBookmark") else {
            return
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                print("⚠️ Bookmark is stale, need to re-select")
                return
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ Cannot access bookmarked resource")
                return
            }
            
            selectedExternalURL = url
            print("✅ Loaded external storage from bookmark: \(url.path)")
        } catch {
            print("❌ Failed to resolve bookmark: \(error)")
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
