import AVFoundation

class CameraManager: NSObject {
    private let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var audioDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureMovieFileOutput()
    private var photoCaptureDelegate: PhotoCaptureDelegate?
    private var videoCaptureDelegate: VideoCaptureDelegate?
    
    var captureSession: AVCaptureSession { session }
    
    override init() {
        super.init()
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
    }
    
    func prepare(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async { [self] in
            do {
                // Setup video input
                let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                
                session.beginConfiguration()
                
                // Add video input
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                    videoDeviceInput = videoInput
                }
                
                // Add audio input for video recording
                if let audioDevice = AVCaptureDevice.default(for: .audio) {
                    do {
                        let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                        if session.canAddInput(audioInput) {
                            session.addInput(audioInput)
                            audioDeviceInput = audioInput
                            print("✅ Audio input added successfully")
                        }
                    } catch {
                        print("⚠️ Could not add audio input: \(error)")
                    }
                }
                
                // Add photo output
                if session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                }
                
                session.commitConfiguration()
                
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("❌ Camera setup error: \(error)")
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
    
    private var currentFlashMode: AVCaptureDevice.FlashMode = .off
    
    func capturePhoto(toExternal: Bool, completion: @escaping (Bool, URL?) -> Void) {
        let settings = AVCapturePhotoSettings()
        
        // Set flash mode
        if photoOutput.supportedFlashModes.contains(currentFlashMode) {
            settings.flashMode = currentFlashMode
        }
        
        // Retain delegate to prevent deallocation
        photoCaptureDelegate = PhotoCaptureDelegate(toExternal: toExternal) { [weak self] success, url in
            completion(success, url)
            // Release delegate after completion
            self?.photoCaptureDelegate = nil
        }
        
        photoOutput.capturePhoto(with: settings, delegate: photoCaptureDelegate!)
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
    
    func toggleFlash() -> AVCaptureDevice.FlashMode {
        guard let device = videoDeviceInput?.device, device.hasFlash else { return .off }
        
        // Cycle through flash modes: off -> on -> auto -> off
        switch currentFlashMode {
        case .off:
            currentFlashMode = .on
        case .on:
            currentFlashMode = .auto
        case .auto:
            currentFlashMode = .off
        @unknown default:
            currentFlashMode = .off
        }
        
        return currentFlashMode
    }
    
    func getFlashMode() -> AVCaptureDevice.FlashMode {
        return currentFlashMode
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
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func focusAt(point: CGPoint, in bounds: CGRect) {
        guard let device = videoDeviceInput?.device else { return }
        
        let focusPoint = CGPoint(
            x: point.y / bounds.height,
            y: 1.0 - point.x / bounds.width
        )
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Focus error: \(error)")
        }
    }
    
    func startRecording(toExternal: Bool, completion: @escaping (URL?, Bool) -> Void) {
        guard videoOutput.connection(with: .video) != nil else {
            completion(nil, false)
            return
        }
        
        let filename = "VID_\(Date().toString()).mov"
        let saveDirectory = StorageManager.shared.getSaveDirectory(forExternal: toExternal)
        let url = saveDirectory.appendingPathComponent(filename)
        
        print("🎥 Starting recording to: \(url.path)")
        
        // Retain delegate to prevent deallocation
        videoCaptureDelegate = VideoCaptureDelegate { [weak self] url, success in
            completion(url, success)
            // Release delegate after completion
            self?.videoCaptureDelegate = nil
        }
        
        videoOutput.startRecording(to: url, recordingDelegate: videoCaptureDelegate!)
    }
    

    
    func stopRecording() {
        if videoOutput.isRecording {
            videoOutput.stopRecording()
        }
    }
}
