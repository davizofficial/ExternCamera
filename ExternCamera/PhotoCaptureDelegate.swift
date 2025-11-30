import AVFoundation
import Photos
import UIKit

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let toExternal: Bool
    private let isSquare: Bool
    private let completion: (Bool, URL?) -> Void
    private let storageManager = StorageManager.shared
    
    init(toExternal: Bool, isSquare: Bool = false, completion: @escaping (Bool, URL?) -> Void) {
        self.toExternal = toExternal
        self.isSquare = isSquare
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("❌ Photo capture error: \(error!.localizedDescription)")
            completion(false, nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              var image = UIImage(data: imageData) else {
            print("❌ Failed to get image data")
            completion(false, nil)
            return
        }
        
        // Crop to square if needed
        if isSquare {
            image = cropToSquare(image: image)
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
            if let croppedData = image.jpegData(compressionQuality: 0.95) {
                self.saveToFileSystem(imageData: croppedData)
            }
        }
    }
    
    private func saveToFileSystem(imageData: Data) {
        let directory = storageManager.getSaveDirectory(forExternal: toExternal)
        let prefix = isSquare ? "SQ_" : "IMG_"
        let filename = "\(prefix)\(Date().toString()).jpg"
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
    
    private func cropToSquare(image: UIImage) -> UIImage {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        // Use the smaller dimension as the square size
        let squareSize = min(originalWidth, originalHeight)
        
        // Calculate crop rect (center crop)
        let x = (originalWidth - squareSize) / 2
        let y = (originalHeight - squareSize) / 2
        let cropRect = CGRect(x: x, y: y, width: squareSize, height: squareSize)
        
        // Crop the image
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
