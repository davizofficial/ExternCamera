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
        
        // ALWAYS save to Photos Library first
        self.saveToPhotosLibrary(imageData: imageData)
        
        // ALSO save to file system (internal or external)
        self.saveToFileSystem(imageData: imageData)
    }
    
    private func saveToPhotosLibrary(imageData: Data) {
        guard let image = UIImage(data: imageData) else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("❌ Photo library access denied")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.creationRequestForAsset(from: image)
                
                // Create album "ExternCamera" if doesn't exist
                if let album = self.getOrCreateAlbum(named: "ExternCamera") {
                    let placeholder = request.placeholderForCreatedAsset
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                    albumChangeRequest?.addAssets([placeholder!] as NSArray)
                }
            }) { success, error in
                if success {
                    print("✅ Photo saved to Photos Library (ExternCamera album)")
                } else {
                    print("❌ Failed to save to Photos: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }
    
    private func saveToFileSystem(imageData: Data) {
        let directory = storageManager.getSaveDirectory(forExternal: toExternal)
        let filename = "IMG_\(Date().formattedForFilename()).jpg"
        let fileURL = directory.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            print("✅ Photo saved to file system: \(fileURL.path)")
            completion(true, fileURL)
        } catch {
            print("❌ Failed to save to file system: \(error)")
            completion(false, nil)
        }
    }
    
    private func getOrCreateAlbum(named albumName: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let album = collection.firstObject {
            return album
        }
        
        // Create album if doesn't exist
        var albumPlaceholder: PHObjectPlaceholder?
        do {
            try PHPhotoLibrary.shared().performChangesAndWait {
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }
            
            if let placeholder = albumPlaceholder {
                let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                return collectionFetchResult.firstObject
            }
        } catch {
            print("❌ Failed to create album: \(error)")
        }
        
        return nil
    }
}
