import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private let cameraManager = CameraManager()
    private let storageManager = StorageManager()
    
    private let previewView = CameraPreviewView()
    private let captureButton = CaptureButton()
    private let toggleCameraButton = ToggleCameraButton()
    private let flashButton = FlashButton()
    private let gridOverlay = GridOverlayView()
    private let zoomSlider = ZoomSliderView()
    private let timerButton = TimerButton()
    
    private var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
        setupGestures()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        view.addSubview(previewView)
        view.addSubview(captureButton)
        view.addSubview(toggleCameraButton)
        view.addSubview(flashButton)
        view.addSubview(gridOverlay)
        view.addSubview(zoomSlider)
        view.addSubview(timerButton)
        
        captureButton.addTarget(self, action: #selector(didPressCapture), for: .touchUpInside)
        toggleCameraButton.addTarget(self, action: #selector(didToggleCamera), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(didToggleFlash), for: .touchUpInside)
        timerButton.addTarget(self, action: #selector(didSelectTimer), for: .touchUpInside)
        zoomSlider.slider.addTarget(self, action: #selector(didChangeZoom), for: .valueChanged)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70)
        ])
        
        toggleCameraButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toggleCameraButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            toggleCameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28)
        ])
        
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            flashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            flashButton.centerYAnchor.constraint(equalTo: toggleCameraButton.centerYAnchor)
        ])
        
        gridOverlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gridOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            gridOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        zoomSlider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            zoomSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            zoomSlider.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -20),
            zoomSlider.widthAnchor.constraint(equalToConstant: 100),
            zoomSlider.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        timerButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            timerButton.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -20)
        ])
    }
    
    private func setupCamera() {
        cameraManager.prepare { [weak self] success in
            if success {
                self?.previewView.session = self?.cameraManager.captureSession
                self?.cameraManager.startSession()
            } else {
                self?.showError("Gagal akses kamera")
            }
        }
    }
    
    private func setupGestures() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        previewView.addGestureRecognizer(pinch)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        cameraManager.setZoom(scale: Float(gesture.scale))
        if gesture.state == .ended { gesture.scale = 1 }
    }
    
    @objc private func didPressCapture() {
        if isRecording {
            cameraManager.stopRecording { url, success in
                if success, let u = url {
                    print("Video disimpan ke: \(u.path)")
                }
                self.isRecording = false
                DispatchQueue.main.async {
                    self.captureButton.isRecording = false
                }
            }
        } else {
            showStorageSelection { useExternal in
                self.cameraManager.capturePhoto(toExternal: useExternal) { success, url in
                    if success {
                        print("Foto disimpan ke: \(url?.path ?? "unknown")")
                    }
                }
            }
        }
    }
    
    @objc private func didToggleCamera() {
        cameraManager.switchCamera()
    }
    
    @objc private func didToggleFlash() {
        let current = cameraManager.toggleFlash()
        flashButton.isOn = current
    }
    
    @objc private func didChangeZoom() {
        cameraManager.setZoom(scale: zoomSlider.slider.value)
    }
    
    @objc private func didSelectTimer() {
        timerButton.showTimerActions { seconds in
            self.startTimer(seconds)
        }
    }
    
    private func startTimer(_ seconds: Int) {
        captureButton.isTimerActive = true
        captureButton.setTitle("\(seconds)", for: .normal)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.captureButton.setTitle("\(seconds - Int(timer.fireDate.timeIntervalSinceNow)))", for: .normal)
            if timer.fireDate.timeIntervalSinceNow <= 0 {
                timer.invalidate()
                self.captureButton.setTitle("", for: .normal)
                self.captureButton.isTimerActive = false
                self.didPressCapture()
            }
        }
    }
    
    private func showStorageSelection(completion: @escaping (Bool) -> Void) {
        let hasExternal = storageManager.isSDCardConnected()
        
        let alert = UIAlertController(title: "Simpan ke", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Memori Internal", style: .default) { _ in
            completion(false)
        })
        
        if hasExternal {
            alert.addAction(UIAlertAction(title: "microSD Card", style: .default) { _ in
                completion(true)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
