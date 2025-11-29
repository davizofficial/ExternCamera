import AVFoundation

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let toExternal: Bool
    private let completion: (Bool, URL?) -> Void
    private let storageManager = StorageManager.shared
    
    init(toExternal: Bool, completion: @escaping (Bool, URL?) -> Void) {
        self.toExternal = toExternal
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            // Ensure delegate is retained until completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                _ = self
            }
        }
        
        guard error == nil else {
            print("❌ Photo capture error: \(error!.localizedDescription)")
            completion(false, nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("❌ Failed to get image data")
            completion(false, nil)
            return
        }
        
        let filename = "IMG_\(Date().toString()).jpg"
        let saveDirectory = storageManager.getSaveDirectory(forExternal: toExternal)
        let url = saveDirectory.appendingPathComponent(filename)
        
        print("📸 Saving photo to: \(url.path)")
        
        do {
            try imageData.write(to: url)
            print("✅ Photo saved successfully: \(url.path)")
            completion(true, url)
        } catch {
            print("❌ Failed to save photo: \(error.localizedDescription)")
            completion(false, nil)
        }
    }
}
