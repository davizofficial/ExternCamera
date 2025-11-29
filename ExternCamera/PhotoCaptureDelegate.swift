import AVFoundation
import Photos
import UIKit

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let toExternal: Bool
    private let completion: (Bool, URL?) -> Void
    private let storageManager = StorageManager.shared
    
    init(toExternal: Bool, completion: @escaping (Bool, URL?) -> Void) {
        self.toExternal = toExternal
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("❌ Photo capture error: \(error!.localizedDescription)")
            completion(false, nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Failed to get image data")
            completion(false, nil)
            return
        }
        
        // Save to Photos Library (galeri iPhone)
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    if success {
                        print("✅ Photo saved to Photos Library")
                    } else {
                        print("❌ Failed to save to Photos: \(error?.localizedDescription ?? "")")
                    }
                }
            } else {
                print("❌ Photo library access denied")
            }
            
            // Also save to file system
            self.saveToFileSystem(imageData: imageData)
        }
    }
    
    private func saveToFileSystem(imageData: Data) {
        let directory = storageManager.getSaveDirectory(forExternal: toExternal)
        let filename = "IMG_\(Date().toString()).jpg"
        let fileURL = directory.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            print("✅ Photo saved to file system: \(fileURL.path)")
            DispatchQueue.main.async {
                self.completion(true, fileURL)
            }
        } catch {
            print("❌ Failed to save to file system: \(error)")
            DispatchQueue.main.async {
                self.completion(false, nil)
            }
        }
    }
}
