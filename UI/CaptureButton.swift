import UIKit

class CaptureButton: UIButton {
    var mode: CameraMode = .photo {
        didSet { updateAppearance() }
    }
    
    var isRecording = false {
        didSet { updateAppearance() }
    }
    
    var isTimerActive = false {
        didSet { updateAppearance() }
    }
    
    private let innerCircle = UIView()
    private let outerRing = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Outer ring (border hitam seperti iOS)
        outerRing.isUserInteractionEnabled = false
        outerRing.backgroundColor = .clear
        outerRing.layer.borderWidth = 3
        outerRing.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
        addSubview(outerRing)
        
        // Inner circle (tombol putih)
        innerCircle.isUserInteractionEnabled = false
        innerCircle.backgroundColor = .white
        addSubview(innerCircle)
        
        // Layout
        outerRing.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            outerRing.centerXAnchor.constraint(equalTo: centerXAnchor),
            outerRing.centerYAnchor.constraint(equalTo: centerYAnchor),
            outerRing.widthAnchor.constraint(equalToConstant: 70),
            outerRing.heightAnchor.constraint(equalToConstant: 70),
            
            innerCircle.centerXAnchor.constraint(equalTo: centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 60),
            innerCircle.heightAnchor.constraint(equalToConstant: 60),
        ])
        
        outerRing.layer.cornerRadius = 35
        innerCircle.layer.cornerRadius = 30
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.curveEaseInOut]) {
            if self.isRecording {
                // Recording: kotak merah kecil
                self.innerCircle.layer.cornerRadius = 8
                self.innerCircle.backgroundColor = .systemRed
                self.innerCircle.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                self.outerRing.layer.borderColor = UIColor.systemRed.cgColor
            } else {
                // Normal: lingkaran putih/merah
                self.innerCircle.layer.cornerRadius = 30
                self.innerCircle.transform = .identity
                self.outerRing.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
                
                if self.mode == .video {
                    self.innerCircle.backgroundColor = .systemRed
                } else {
                    self.innerCircle.backgroundColor = .white
                }
            }
        }
    }
    
    // Animasi saat di-tap
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
        }
    }
}