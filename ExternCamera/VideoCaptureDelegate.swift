import AVFoundation
import Photos

class VideoCaptureDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    private let completion: (URL?, Bool) -> Void
    
    init(completion: @escaping (URL?, Bool) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("🎥 Started recording to: \(fileURL.path)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        defer {
            // Ensure delegate is retained until completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                _ = self
            }
        }
        
        if let error = error {
            print("❌ Video recording error: \(error.localizedDescription)")
            completion(nil, false)
            return
        }
        
        guard FileManager.default.fileExists(atPath: outputFileURL.path) else {
            print("❌ Video file not found at: \(outputFileURL.path)")
            completion(nil, false)
            return
        }
        
        print("🎥 Video recorded at: \(outputFileURL.path)")
        
        // Save to Photos Library (galeri iPhone)
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("❌ Photo library access denied")
                // Still report success with file URL
                self.completion(outputFileURL, true)
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .video, fileURL: outputFileURL, options: nil)
                
                // Create album "ExternCamera" if doesn't exist
                if let album = self.getOrCreateAlbum(named: "ExternCamera") {
                    let placeholder = request.placeholderForCreatedAsset
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                    albumChangeRequest?.addAssets([placeholder!] as NSArray)
                }
            }) { success, error in
                if success {
                    print("✅ Video saved to Photos Library (ExternCamera album)")
                } else {
                    print("❌ Failed to save video to Photos: \(error?.localizedDescription ?? "")")
                }
                
                // Always report success with file URL
                self.completion(outputFileURL, true)
            }
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
