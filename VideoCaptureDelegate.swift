import AVFoundation

class VideoCaptureDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    static var recordingCompletion: ((URL?, Bool) -> Void)?
    private let completion: (URL?, Bool) -> Void
    
    init(completion: @escaping (URL?, Bool) -> Void) {
        self.completion = completion
        super.init()
        VideoCaptureDelegate.recordingCompletion = completion
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let success = (error == nil) && !outputFileURL.path.hasPrefix("/invalid")
        completion(outputFileURL, success)
        VideoCaptureDelegate.recordingCompletion = nil
    }
}
