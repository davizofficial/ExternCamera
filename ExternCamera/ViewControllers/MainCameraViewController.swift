import UIKit
import AVFoundation

class MainCameraViewController: UIViewController {
    
    // MARK: - Properties
    private let cameraManager = CameraManager()
    private let storageManager = StorageManager.shared
    private let settings = CameraSettings.shared
    
    private var currentMode: CameraMode = .photo
    private var isRecording = false
    private var recordingTimer: Timer?
    private var recordingDuration: TimeInterval = 0
    private var selectedStorageType: StorageType = .internal
    private var hasSelectedStorage = false
    
    // MARK: - UI Components
    private let previewView = CameraPreviewView()
    private let topControlsView = UIView()
    private let bottomControlsView = UIView()
    private let modeSelector = ModeSelectorView()
    
    // Top controls
    private let flashButton = UIButton(type: .system)
    private let hdrButton = UIButton(type: .system)
    private let livePhotoButton = UIButton(type: .system)
    private let timerButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    
    // Bottom controls
    private let captureButton = CaptureButton()
    private let switchCameraButton = UIButton(type: .system)
    private let thumbnailButton = UIButton(type: .system)
    
    // Overlays
    private let gridOverlay = GridOverlayView()
    private let focusGuideView = UIView()
    private let squareFrameOverlay = SquareFrameOverlay()
    private let recordingLabel = UILabel()
    private let zoomSlider = UISlider()
    
    // Panorama
    private var panoramaImages: [UIImage] = []
    private var isPanoramaMode = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
        updateUIForMode()
        updateThumbnail()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Show storage selection popup on first launch
        if !hasSelectedStorage {
            showStorageSelection()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraManager.startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraManager.stopSession()
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // Preview fullscreen tanpa border
        view.addSubview(previewView)
        
        // Grid overlay
        view.addSubview(gridOverlay)
        gridOverlay.isHidden = !settings.showGrid
        
        // Square overlay (untuk mode square)
        view.addSubview(squareFrameOverlay)
        squareFrameOverlay.isHidden = true
        
        // Focus guide (kotak kuning di tengah seperti di gambar)
        setupFocusGuide()
        
        // Top controls
        setupTopControls()
        
        // Bottom controls
        setupBottomControls()
        
        // Mode selector
        view.addSubview(modeSelector)
        modeSelector.delegate = self
        
        // Recording label
        setupRecordingLabel()
        
        // Zoom slider
        setupZoomSlider()
        
        setupConstraints()
        setupGestures()
    }
    
    private func setupFocusGuide() {
        // Focus guide disembunyikan secara default
        view.addSubview(focusGuideView)
        focusGuideView.backgroundColor = .clear
        focusGuideView.isUserInteractionEnabled = false
        focusGuideView.isHidden = true
    }
    
    private func setupTopControls() {
        view.addSubview(topControlsView)
        topControlsView.backgroundColor = .clear
        
        // Flash button
        flashButton.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
        flashButton.tintColor = .white
        flashButton.addTarget(self, action: #selector(didTapFlash), for: .touchUpInside)
        addButtonAnimation(to: flashButton)
        topControlsView.addSubview(flashButton)
        
        // HDR button
        hdrButton.setTitle("HDR", for: .normal)
        hdrButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        hdrButton.tintColor = .white
        hdrButton.addTarget(self, action: #selector(didTapHDR), for: .touchUpInside)
        topControlsView.addSubview(hdrButton)
        
        // Live Photo button
        livePhotoButton.setImage(UIImage(systemName: "livephoto"), for: .normal)
        livePhotoButton.tintColor = .white
        livePhotoButton.addTarget(self, action: #selector(didTapLivePhoto), for: .touchUpInside)
        addButtonAnimation(to: livePhotoButton)
        topControlsView.addSubview(livePhotoButton)
        
        // Timer button
        timerButton.setImage(UIImage(systemName: "timer"), for: .normal)
        timerButton.tintColor = .white
        timerButton.addTarget(self, action: #selector(didTapTimer), for: .touchUpInside)
        addButtonAnimation(to: timerButton)
        topControlsView.addSubview(timerButton)
        
        // Settings button (gear icon)
        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingsButton.tintColor = .white
        settingsButton.addTarget(self, action: #selector(didTapSettings), for: .touchUpInside)
        addButtonAnimation(to: settingsButton)
        topControlsView.addSubview(settingsButton)
    }
    
    private func setupBottomControls() {
        view.addSubview(bottomControlsView)
        bottomControlsView.backgroundColor = .clear
        
        // Capture button
        captureButton.addTarget(self, action: #selector(didTapCapture), for: .touchUpInside)
        bottomControlsView.addSubview(captureButton)
        
        // Switch camera
        switchCameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        switchCameraButton.tintColor = .white
        switchCameraButton.addTarget(self, action: #selector(didTapSwitchCamera), for: .touchUpInside)
        addButtonAnimation(to: switchCameraButton)
        bottomControlsView.addSubview(switchCameraButton)
        
        // Thumbnail - dengan border hitam seperti iOS
        thumbnailButton.backgroundColor = .darkGray
        thumbnailButton.layer.cornerRadius = 8
        thumbnailButton.layer.borderWidth = 2.5
        thumbnailButton.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
        thumbnailButton.clipsToBounds = true
        thumbnailButton.contentMode = .scaleAspectFill
        thumbnailButton.addTarget(self, action: #selector(didTapThumbnail), for: .touchUpInside)
        
        // Placeholder icon
        let placeholderImage = UIImage(systemName: "photo.on.rectangle")
        thumbnailButton.setImage(placeholderImage, for: .normal)
        thumbnailButton.tintColor = .white
        thumbnailButton.imageView?.contentMode = .scaleAspectFit
        
        bottomControlsView.addSubview(thumbnailButton)
    }
    
    private func setupRecordingLabel() {
        recordingLabel.textColor = .red
        recordingLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        recordingLabel.text = "00:00"
        recordingLabel.isHidden = true
        view.addSubview(recordingLabel)
    }
    
    private func setupZoomSlider() {
        zoomSlider.minimumValue = 1.0
        zoomSlider.maximumValue = 5.0
        zoomSlider.value = 1.0
        zoomSlider.alpha = 0
        zoomSlider.addTarget(self, action: #selector(didChangeZoom), for: .valueChanged)
        view.addSubview(zoomSlider)
    }
    
    private func setupConstraints() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        gridOverlay.translatesAutoresizingMaskIntoConstraints = false
        topControlsView.translatesAutoresizingMaskIntoConstraints = false
        bottomControlsView.translatesAutoresizingMaskIntoConstraints = false
        modeSelector.translatesAutoresizingMaskIntoConstraints = false
        recordingLabel.translatesAutoresizingMaskIntoConstraints = false
        zoomSlider.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Preview fullscreen
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Grid overlay matches preview
            gridOverlay.topAnchor.constraint(equalTo: previewView.topAnchor),
            gridOverlay.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            gridOverlay.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
            gridOverlay.bottomAnchor.constraint(equalTo: previewView.bottomAnchor),
            
            // Square frame overlay matches preview
            squareFrameOverlay.topAnchor.constraint(equalTo: previewView.topAnchor),
            squareFrameOverlay.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            squareFrameOverlay.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
            squareFrameOverlay.bottomAnchor.constraint(equalTo: previewView.bottomAnchor),
            
            // Top controls
            topControlsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topControlsView.heightAnchor.constraint(equalToConstant: 50),
            
            // Bottom controls
            bottomControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomControlsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomControlsView.heightAnchor.constraint(equalToConstant: 120),
            
            // Mode selector
            modeSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modeSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            modeSelector.bottomAnchor.constraint(equalTo: bottomControlsView.topAnchor, constant: -10),
            modeSelector.heightAnchor.constraint(equalToConstant: 40),
            
            // Recording label
            recordingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordingLabel.topAnchor.constraint(equalTo: topControlsView.bottomAnchor, constant: 10),
            
            // Zoom slider
            zoomSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            zoomSlider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            zoomSlider.widthAnchor.constraint(equalToConstant: 150),
        ])
        
        // Focus guide di tengah
        focusGuideView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            focusGuideView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            focusGuideView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            focusGuideView.widthAnchor.constraint(equalToConstant: 200),
            focusGuideView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        // Top controls buttons - layout seperti di gambar
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        hdrButton.translatesAutoresizingMaskIntoConstraints = false
        livePhotoButton.translatesAutoresizingMaskIntoConstraints = false
        timerButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Flash (X) di kiri
            flashButton.leadingAnchor.constraint(equalTo: topControlsView.leadingAnchor, constant: 20),
            flashButton.centerYAnchor.constraint(equalTo: topControlsView.centerYAnchor),
            flashButton.widthAnchor.constraint(equalToConstant: 44),
            flashButton.heightAnchor.constraint(equalToConstant: 44),
            
            // HDR di tengah kiri
            hdrButton.leadingAnchor.constraint(equalTo: flashButton.trailingAnchor, constant: 30),
            hdrButton.centerYAnchor.constraint(equalTo: topControlsView.centerYAnchor),
            
            // Live Photo di tengah
            livePhotoButton.centerXAnchor.constraint(equalTo: topControlsView.centerXAnchor),
            livePhotoButton.centerYAnchor.constraint(equalTo: topControlsView.centerYAnchor),
            livePhotoButton.widthAnchor.constraint(equalToConstant: 44),
            livePhotoButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Timer di kanan
            timerButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -20),
            timerButton.centerYAnchor.constraint(equalTo: topControlsView.centerYAnchor),
            timerButton.widthAnchor.constraint(equalToConstant: 44),
            timerButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Settings (profile) di paling kanan
            settingsButton.trailingAnchor.constraint(equalTo: topControlsView.trailingAnchor, constant: -20),
            settingsButton.centerYAnchor.constraint(equalTo: topControlsView.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        // Bottom controls buttons
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        thumbnailButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: bottomControlsView.centerXAnchor),
            captureButton.centerYAnchor.constraint(equalTo: bottomControlsView.centerYAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            switchCameraButton.trailingAnchor.constraint(equalTo: bottomControlsView.trailingAnchor, constant: -30),
            switchCameraButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 40),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 40),
            
            thumbnailButton.leadingAnchor.constraint(equalTo: bottomControlsView.leadingAnchor, constant: 30),
            thumbnailButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            thumbnailButton.widthAnchor.constraint(equalToConstant: 50),
            thumbnailButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func setupGestures() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        previewView.addGestureRecognizer(pinch)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        previewView.addGestureRecognizer(tap)
    }
    
    private func setupCamera() {
        cameraManager.prepare { [weak self] success in
            if success {
                self?.previewView.session = self?.cameraManager.captureSession
            } else {
                self?.showAlert(title: "Error", message: "Gagal mengakses kamera")
            }
        }
    }
    
    // MARK: - Actions
    @objc private func didTapCapture() {
        switch currentMode {
        case .photo:
            capturePhoto()
        case .square:
            captureSquarePhoto()
        case .video:
            toggleVideoRecording()
        case .pano:
            capturePanorama()
        }
    }
    
    private func capturePhoto() {
        // Langsung save ke storage yang dipilih
        let useExternal = (selectedStorageType == .external)
        
        // Cek apakah external storage masih tersedia jika dipilih
        if useExternal && !storageManager.isExternalStorageAvailable() {
            showAlert(title: "Storage Error", message: "External storage not available. Please reconnect USB drive or select internal storage.")
            return
        }
        
        cameraManager.capturePhoto(toExternal: useExternal) { [weak self] success, url in
            if success {
                let storageName = useExternal ? "External USB" : "Internal"
                print("✅ Foto disimpan ke \(storageName): \(url?.path ?? "")")
                self?.updateThumbnail()
                self?.showSaveConfirmation(path: url?.path ?? "")
            } else {
                self?.showAlert(title: "Error", message: "Gagal menyimpan foto")
            }
        }
    }
    
    private func captureSquarePhoto() {
        let useExternal = (selectedStorageType == .external)
        
        if useExternal && !storageManager.isExternalStorageAvailable() {
            showAlert(title: "Storage Error", message: "External storage not available. Please reconnect USB drive or select internal storage.")
            return
        }
        
        // Capture photo biasa, tapi akan di-crop menjadi square di PhotoCaptureDelegate
        cameraManager.captureSquarePhoto(toExternal: useExternal) { [weak self] success, url in
            if success {
                let storageName = useExternal ? "External USB" : "Internal"
                print("✅ Square foto disimpan ke \(storageName): \(url?.path ?? "")")
                self?.updateThumbnail()
                self?.showSaveConfirmation(path: url?.path ?? "")
            } else {
                self?.showAlert(title: "Error", message: "Gagal menyimpan square foto")
            }
        }
    }
    
    private func capturePanorama() {
        if !isPanoramaMode {
            // Start panorama mode
            isPanoramaMode = true
            panoramaImages = []
            showPanoramaInstructions()
            
            // Change capture button appearance
            captureButton.setTitle("Capture Frame", for: .normal)
            captureButton.backgroundColor = .systemGreen
        } else {
            // Capture current frame
            capturePanoramaFrame()
        }
    }
    
    private func showPanoramaInstructions() {
        let alert = UIAlertController(
            title: "Panorama Mode",
            message: "Tap the capture button to take multiple photos. Move camera slowly between shots. Tap 'Done' when finished.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Start", style: .default))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.cancelPanorama()
        })
        present(alert, animated: true)
    }
    
    private func capturePanoramaFrame() {
        cameraManager.capturePhoto(toExternal: false) { [weak self] success, url in
            guard let self = self, success, let url = url else { return }
            
            // Load captured image
            if let image = UIImage(contentsOfFile: url.path) {
                self.panoramaImages.append(image)
                
                // Show progress
                let count = self.panoramaImages.count
                self.showAlert(title: "Frame \(count) Captured", message: "Captured \(count) frame(s). Move camera and tap again, or tap 'Done'.")
                
                // After 3+ frames, offer to finish
                if count >= 3 {
                    self.offerToFinishPanorama()
                }
            }
        }
    }
    
    private func offerToFinishPanorama() {
        let alert = UIAlertController(
            title: "Panorama Progress",
            message: "You have captured \(panoramaImages.count) frames. Continue or finish?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Continue", style: .default))
        alert.addAction(UIAlertAction(title: "Finish", style: .default) { [weak self] _ in
            self?.finishPanorama()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.cancelPanorama()
        })
        present(alert, animated: true)
    }
    
    private func finishPanorama() {
        guard panoramaImages.count >= 2 else {
            showAlert(title: "Error", message: "Need at least 2 frames for panorama")
            return
        }
        
        // Stitch images horizontally
        let stitchedImage = stitchPanoramaImages(panoramaImages)
        
        // Save stitched panorama
        let useExternal = (selectedStorageType == .external)
        savePanoramaImage(stitchedImage, toExternal: useExternal)
        
        // Reset panorama mode
        isPanoramaMode = false
        panoramaImages = []
        captureButton.setTitle(nil, for: .normal)
        captureButton.backgroundColor = .clear
        
        showAlert(title: "Success", message: "Panorama saved!")
    }
    
    private func cancelPanorama() {
        isPanoramaMode = false
        panoramaImages = []
        captureButton.setTitle(nil, for: .normal)
        captureButton.backgroundColor = .clear
    }
    
    private func stitchPanoramaImages(_ images: [UIImage]) -> UIImage {
        // Simple horizontal stitching
        let totalWidth = images.reduce(0) { $0 + $1.size.width }
        let maxHeight = images.map { $0.size.height }.max() ?? 0
        
        let size = CGSize(width: totalWidth, height: maxHeight)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        var xOffset: CGFloat = 0
        for image in images {
            image.draw(at: CGPoint(x: xOffset, y: 0))
            xOffset += image.size.width
        }
        
        let stitchedImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        
        return stitchedImage
    }
    
    private func savePanoramaImage(_ image: UIImage, toExternal: Bool) {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else { return }
        
        let directory = storageManager.getSaveDirectory(forExternal: toExternal)
        let filename = "PANO_\(Date().toString()).jpg"
        let fileURL = directory.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            print("✅ Panorama saved: \(fileURL.path)")
            updateThumbnail()
            showSaveConfirmation(path: fileURL.path)
        } catch {
            print("❌ Failed to save panorama: \(error)")
            showAlert(title: "Error", message: "Failed to save panorama")
        }
    }
    
    private func toggleVideoRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // Langsung save ke storage yang dipilih
        let useExternal = (selectedStorageType == .external)
        
        // Cek apakah external storage masih tersedia jika dipilih
        if useExternal && !storageManager.isExternalStorageAvailable() {
            showAlert(title: "Storage Error", message: "External storage not available. Please reconnect USB drive or select internal storage.")
            return
        }
        
        cameraManager.startRecording(toExternal: useExternal) { [weak self] url, success in
            if success {
                let storageName = useExternal ? "External USB" : "Internal"
                print("✅ Video disimpan ke \(storageName): \(url?.path ?? "")")
                self?.updateThumbnail()
                self?.showSaveConfirmation(path: url?.path ?? "")
            }
        }
        
        isRecording = true
        recordingDuration = 0
        recordingLabel.isHidden = false
        captureButton.isRecording = true
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.recordingDuration += 1
            self?.updateRecordingLabel()
        }
    }
    
    private func stopRecording() {
        cameraManager.stopRecording()
        
        isRecording = false
        recordingLabel.isHidden = true
        captureButton.isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func updateRecordingLabel() {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        recordingLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    @objc private func didTapFlash() {
        _ = cameraManager.toggleFlash()
        updateFlashButton()
    }
    
    @objc private func didTapHDR() {
        settings.hdrEnabled.toggle()
        updateHDRButton()
    }
    
    @objc private func didTapLivePhoto() {
        settings.livePhotoEnabled.toggle()
        updateLivePhotoButton()
    }
    
    @objc private func didTapTimer() {
        let modes: [TimerMode] = [.off, .three, .ten]
        let currentIndex = modes.firstIndex(of: settings.timerMode) ?? 0
        let nextIndex = (currentIndex + 1) % modes.count
        settings.timerMode = modes[nextIndex]
        updateTimerButton()
    }
    
    @objc private func didTapSettings() {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let settingsVC = SettingsViewController()
        settingsVC.currentStorageType = selectedStorageType
        settingsVC.onStorageChange = { [weak self] type in
            self?.selectedStorageType = type
            self?.updateStorageIndicator()
        }
        
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.modalPresentationStyle = .pageSheet
        
        // Smooth animation
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    @objc private func didTapSwitchCamera() {
        // Animasi flip seperti iOS
        UIView.transition(with: previewView, duration: 0.5, options: .transitionFlipFromLeft) {
            self.cameraManager.switchCamera()
        }
    }
    
    @objc private func didTapThumbnail() {
        let galleryVC = GalleryViewController()
        let navController = UINavigationController(rootViewController: galleryVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            let newZoom = zoomSlider.value * Float(gesture.scale)
            zoomSlider.value = min(max(newZoom, 1.0), 5.0)
            cameraManager.setZoom(scale: zoomSlider.value)
            
            UIView.animate(withDuration: 0.2) {
                self.zoomSlider.alpha = 1.0
            }
        } else if gesture.state == .ended {
            gesture.scale = 1.0
            UIView.animate(withDuration: 0.5, delay: 1.0) {
                self.zoomSlider.alpha = 0
            }
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: previewView)
        cameraManager.focusAt(point: point, in: previewView.bounds)
        showFocusIndicator(at: point)
    }
    
    @objc private func didChangeZoom(_ slider: UISlider) {
        cameraManager.setZoom(scale: slider.value)
    }
    
    // MARK: - UI Updates
    private func updateUIForMode() {
        captureButton.mode = currentMode
        
        // Show/hide square frame overlay
        squareFrameOverlay.isHidden = (currentMode != .square)
        
        switch currentMode {
        case .video:
            flashButton.isHidden = false
            hdrButton.isHidden = true
            livePhotoButton.isHidden = true
            timerButton.isHidden = true
        case .photo:
            flashButton.isHidden = false
            hdrButton.isHidden = false
            livePhotoButton.isHidden = false
            timerButton.isHidden = false
        case .square:
            flashButton.isHidden = false
            hdrButton.isHidden = false
            livePhotoButton.isHidden = true
            timerButton.isHidden = false
        case .pano:
            flashButton.isHidden = true
            hdrButton.isHidden = true
            livePhotoButton.isHidden = true
            timerButton.isHidden = false
        }
        
        // Update button states
        updateFlashButton()
        updateHDRButton()
        updateLivePhotoButton()
        updateTimerButton()
    }
    
    private func updateFlashButton() {
        let iconName: String
        let flashMode = cameraManager.getFlashMode()
        switch flashMode {
        case .off: iconName = "bolt.slash.fill"
        case .auto: iconName = "bolt.badge.a.fill"
        case .on: iconName = "bolt.fill"
        @unknown default: iconName = "bolt.slash.fill"
        }
        flashButton.setImage(UIImage(systemName: iconName), for: .normal)
    }
    
    private func updateHDRButton() {
        hdrButton.alpha = settings.hdrEnabled ? 1.0 : 0.5
    }
    
    private func updateLivePhotoButton() {
        let iconName = settings.livePhotoEnabled ? "livephoto" : "livephoto.slash"
        livePhotoButton.setImage(UIImage(systemName: iconName), for: .normal)
    }
    
    private func updateTimerButton() {
        let iconName = settings.timerMode == .off ? "timer" : "timer.circle.fill"
        timerButton.setImage(UIImage(systemName: iconName), for: .normal)
    }
    
    private func updateThumbnail() {
        // Load foto terakhir dari storage
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let useExternal = (self.selectedStorageType == .external)
            let directory = self.storageManager.getSaveDirectory(forExternal: useExternal)
            
            do {
                let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
                
                // Filter hanya foto/video
                let mediaFiles = files.filter { url in
                    let ext = url.pathExtension.lowercased()
                    return ["jpg", "jpeg", "png", "heic", "mov", "mp4"].contains(ext)
                }
                
                // Sort by creation date, ambil yang terbaru
                let sortedFiles = mediaFiles.sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
                
                if let latestFile = sortedFiles.first {
                    // Load thumbnail
                    if latestFile.pathExtension.lowercased() == "mov" || latestFile.pathExtension.lowercased() == "mp4" {
                        // Video thumbnail
                        self.loadVideoThumbnail(from: latestFile)
                    } else {
                        // Photo thumbnail
                        if let image = UIImage(contentsOfFile: latestFile.path) {
                            DispatchQueue.main.async {
                                self.thumbnailButton.setImage(image, for: .normal)
                                self.thumbnailButton.imageView?.contentMode = .scaleAspectFill
                            }
                        }
                    }
                }
            } catch {
                print("Error loading thumbnail: \(error)")
            }
        }
    }
    
    private func loadVideoThumbnail(from url: URL) {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 0, preferredTimescale: 1)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            DispatchQueue.main.async { [weak self] in
                self?.thumbnailButton.setImage(thumbnail, for: .normal)
                self?.thumbnailButton.imageView?.contentMode = .scaleAspectFill
            }
        } catch {
            print("Error generating video thumbnail: \(error)")
        }
    }
    
    private func showFocusIndicator(at point: CGPoint) {
        let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        focusView.center = point
        focusView.layer.borderColor = UIColor.yellow.cgColor
        focusView.layer.borderWidth = 2
        focusView.alpha = 0
        previewView.addSubview(focusView)
        
        UIView.animate(withDuration: 0.2, animations: {
            focusView.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0.5, animations: {
                focusView.alpha = 0
            }) { _ in
                focusView.removeFromSuperview()
            }
        }
    }
    
    private func showStorageSelection() {
        let storageVC = StorageSelectionViewController()
        storageVC.delegate = self
        storageVC.modalPresentationStyle = .overFullScreen
        storageVC.modalTransitionStyle = .crossDissolve
        present(storageVC, animated: true)
    }
    
    private func showSaveConfirmation(path: String) {
        let storageName = selectedStorageType == .external ? "USB Drive" : "Internal Storage"
        
        // Show brief confirmation
        let label = UILabel()
        label.text = "Saved to \(storageName)"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.alpha = 0
        
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            label.widthAnchor.constraint(equalToConstant: 200),
            label.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            label.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, animations: {
                label.alpha = 0
            }) { _ in
                label.removeFromSuperview()
            }
        }
    }
    
    private func addButtonAnimation(to button: UIButton) {
        button.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseInOut]) {
            sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            sender.alpha = 0.7
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [.curveEaseInOut]) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - StorageSelectionDelegate
extension MainCameraViewController: StorageSelectionDelegate {
    func didSelectStorage(type: StorageType) {
        selectedStorageType = type
        hasSelectedStorage = true
        
        let storageName = type == .external ? "USB Drive" : "Internal Storage"
        print("✅ Storage dipilih: \(storageName)")
        
        // Update settings button badge atau indicator
        updateStorageIndicator()
    }
    
    private func updateStorageIndicator() {
        // Bisa tambahkan indicator di UI untuk menunjukkan storage yang aktif
        let color: UIColor = selectedStorageType == .external ? .systemGreen : .systemBlue
        settingsButton.tintColor = color
    }
}

// MARK: - ModeSelectorDelegate
extension MainCameraViewController: ModeSelectorDelegate {
    func didSelectMode(_ mode: CameraMode) {
        currentMode = mode
        updateUIForMode()
    }
}
