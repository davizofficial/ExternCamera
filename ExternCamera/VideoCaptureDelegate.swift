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
        if let error = error {
            print("❌ Video recording error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.completion(nil, false)
            }
            return
        }
        
        guard FileManager.default.fileExists(atPath: outputFileURL.path) else {
            print("❌ Video file not found at: \(outputFileURL.path)")
            DispatchQueue.main.async {
                self.completion(nil, false)
            }
            return
        }
        
        print("🎥 Video recorded at: \(outputFileURL.path)")
        
        // Save to Photos Library (galeri iPhone)
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .video, fileURL: outputFileURL, options: nil)
                }) { success, error in
                    if success {
                        print("✅ Video saved to Photos Library")
                    } else {
                        print("❌ Failed to save video to Photos: \(error?.localizedDescription ?? "")")
                    }
                    
                    // Report completion
                    DispatchQueue.main.async {
                        self.completion(outputFileURL, true)
                    }
                }
            } else {
                print("❌ Photo library access denied")
                DispatchQueue.main.async {
                    self.completion(outputFileURL, true)
                }
            }
        }
    }
}
