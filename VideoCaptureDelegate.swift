import AVFoundation

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
        
        let success = FileManager.default.fileExists(atPath: outputFileURL.path)
        if success {
            print("✅ Video saved successfully: \(outputFileURL.path)")
        } else {
            print("❌ Video file not found at: \(outputFileURL.path)")
        }
        
        completion(outputFileURL, success)
    }
}
