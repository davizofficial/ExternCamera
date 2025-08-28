import AVFoundation

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let toExternal: Bool
    private let completion: (Bool, URL?) -> Void
    private let storageManager = StorageManager()
    
    init(toExternal: Bool, completion: @escaping (Bool, URL?) -> Void) {
        self.toExternal = toExternal
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            completion(false, nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            completion(false, nil)
            return
        }
        
        let filename = "IMG_\(Date().toString()).jpg"
        let saveDirectory = storageManager.getSaveDirectory(forExternal: toExternal)
        let url = saveDirectory.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: url)
            completion(true, url)
        } catch {
            print("Gagal simpan: \(error)")
            completion(false, nil)
        }
    }
}
