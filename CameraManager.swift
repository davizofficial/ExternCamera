import AVFoundation

class CameraManager: NSObject {
    private let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureMovieFileOutput()
    
    var captureSession: AVCaptureSession { session }
    
    override init() {
        super.init()
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
    }
    
    func prepare(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
                let input = try AVCaptureDeviceInput(device: device)
                
                session.beginConfiguration()
                if session.canAddInput(input) {
                    session.addInput(input)
                    videoDeviceInput = input
                }
                
                if session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                }
                
                session.commitConfiguration()
                
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("Error: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    func startSession() {
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    func capturePhoto(toExternal: Bool, completion: @escaping (Bool, URL?) -> Void) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        let delegate = PhotoCaptureDelegate(toExternal: toExternal, completion: completion)
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
    
    func switchCamera() {
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else { return }
        
        session.beginConfiguration()
        session.removeInput(currentInput)
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                videoDeviceInput = newInput
            }
        } catch {
            print("Gagal ganti kamera: \(error)")
        }
        
        session.commitConfiguration()
    }
    
    func toggleFlash() -> Bool {
        guard let device = videoDeviceInput?.device, device.hasFlash else { return false }
        do {
            try device.lockForConfiguration()
            let mode = device.flashMode == .on ? AVCaptureDevice.FlashMode.off : .on
            device.flashMode = mode
            device.unlockForConfiguration()
            return mode == .on
        } catch {
            return false
        }
    }
    
    func setZoom(scale: Float) {
        let max = videoDeviceInput?.device.activeFormat.videoMaxZoomFactor ?? 1.0
        let zoom = min(CGFloat(scale), max)
        do {
            try videoDeviceInput?.device.lockForConfiguration()
            videoDeviceInput?.device.videoZoomFactor = zoom
            videoDeviceInput?.device.unlockForConfiguration()
        } catch {
            print("Zoom gagal: \(error)")
        }
    }
}

// MARK: - Video Recording Extension
extension CameraManager {
    func startRecording(completion: @escaping (URL?, Bool) -> Void) {
        guard let connection = videoOutput.connection(with: .video) else {
            completion(nil, false)
            return
        }
        
        let filename = "VID_\(Date().toString()).mov"
        let saveDirectory = StorageManager().getSaveDirectory(forExternal: true)
        let url = saveDirectory.appendingPathComponent(filename)
        
        videoOutput.startRecording(to: url, recordingDelegate: VideoCaptureDelegate(completion: completion))
    }
    
    func stopRecording(completion: @escaping (URL?, Bool) -> Void) {
        videoOutput.stopRecording()
        VideoCaptureDelegate.recordingCompletion = completion
    }
}
