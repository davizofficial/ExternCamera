import UIKit

class CaptureButton: UIButton {
    var isRecording = false {
        didSet { update() }
    }
    var isTimerActive = false {
        didSet { update() }
    }
    
    private func update() {
        backgroundColor = isRecording ? .red : .clear
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = isRecording ? 0 : 4
        layer.cornerRadius = 35
        setTitleColor(.white, for: .normal)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        layer.borderWidth = 4
        layer.borderColor = UIColor.white.cgColor
        layer.cornerRadius = 35
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
    }
}